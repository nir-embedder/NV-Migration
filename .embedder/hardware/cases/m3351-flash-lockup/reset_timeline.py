"""Reset-release timeline capture for the M3351 lockup state.

Authorized diagnostic category: interface open, debug-register writes
(DHCSR/DEMCR only), nRESET/SYSRESETREQ. No flash, configuration, security,
LDROM or SRAM writes. The target is left halted if a halt is achieved; it is
never resumed by this script.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
reset_kind = capture_profile.get("reset", "pin")
if reset_kind not in ("pin", "sysresetreq", "none"):
    raise ValueError("reset must be pin, sysresetreq or none")
samples = int(capture_profile.get("samples", 400))
spam_halt = bool(capture_profile.get("spam_halt", False))
frequency = int(capture_profile.get("frequency", 1000000))
if frequency not in (100000, 1000000, 2000000):
    raise ValueError("unsupported SWD frequency")

code = r'''
import json
from time import monotonic, sleep
from datetime import datetime, timezone
from pathlib import Path
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address, MEM_AP_CSW
from pyocd.core.exceptions import TransferError

root = Path.cwd()
DHCSR = 0xe000edf0; DCRSR = 0xe000edf4; DCRDR = 0xe000edf8; DEMCR = 0xe000edfc
DAUTH = 0xe000efb8; DSCSR = 0xe000ee08; AIRCR = 0xe000ed0c
CFSR = 0xe000ed28; HFSR = 0xe000ed2c; SFSR = 0xe000ede4
S_HALT = 1 << 17; S_LOCKUP = 1 << 19; S_RETIRE = 1 << 24; S_RESET = 1 << 25; S_SDE = 1 << 20
DBGKEY = 0xa05f0000

info = {"timestamp": datetime.now(timezone.utc).isoformat(),
        "reset": RESET, "frequency": FREQUENCY, "spam_halt": SPAM_HALT,
        "scope": "debug-register writes and reset only; no flash/config/security/RAM writes; not resumed"}

def rd(ap, addr):
    try:
        return hex(ap.read32(addr))
    except Exception as exc:
        return {"error": str(exc)}

def safe(fn):
    try:
        return fn()
    except Exception as exc:
        return {"error": str(exc)}

def core_reg(ap, sel):
    ap.write32(DCRSR, sel)
    for _ in range(100):
        if ap.read32(DHCSR) & (1 << 16):
            return hex(ap.read32(DCRDR))
    return {"error": "S_REGRDY timeout"}

def snapshot(ap, dp):
    out = {}
    for name, addr in (("DHCSR", DHCSR), ("DEMCR", DEMCR), ("DAUTHSTATUS", DAUTH), ("DSCSR", DSCSR),
                       ("CFSR", CFSR), ("HFSR", HFSR), ("SFSR", SFSR),
                       ("SYS_PDID", 0x40000000), ("SYS_RSTSTS", 0x40000004),
                       ("FMC_ISPCTL", 0x4000c000), ("FMC_ISPSTS", 0x4000c040),
                       ("SCU_FNSADDR", 0x4002f02c), ("SCU_SRAMNSSET", 0x4002f020),
                       ("APROM_0", 0x0), ("APROM_4", 0x4), ("SRAM_0", 0x20000000),
                       ("CONFIG0_direct", 0x0f300000)):
        out[name] = rd(ap, addr)
    out["dp_ctrl_stat"] = safe(lambda: hex(dp.read_reg(DP_CTRL_STAT)))
    out["csw"] = safe(lambda: hex(ap.read_reg(MEM_AP_CSW)))
    return out

def halted_regs(ap):
    regs = {}
    for name, sel in (("r0", 0), ("sp", 13), ("lr", 14), ("pc", 15), ("xpsr", 16),
                      ("msp", 17), ("psp", 18), ("control_primask", 20),
                      ("msp_ns", 24), ("psp_ns", 25), ("msp_s", 0x22), ("psp_s", 0x23),
                      ("msplim_s", 0x1c), ("psplim_s", 0x1d), ("msplim_ns", 0x1e), ("psplim_ns", 0x1f)):
        regs[name] = safe(lambda sel=sel: core_reg(ap, sel))
    return regs

def sample_loop(ap, label, n, halt_write=False):
    rows = []
    t0 = monotonic()
    counts = {"reset_st": 0, "retire_st": 0, "lockup": 0, "halt": 0, "errors": 0}
    halted = False
    for i in range(n):
        try:
            if halt_write:
                ap.write32(DHCSR, DBGKEY | 0x3)
            d = ap.read32(DHCSR)
            a = ap.read32(DAUTH)
        except Exception as exc:
            counts["errors"] += 1
            rows.append({"i": i, "t_ms": round((monotonic() - t0) * 1000, 3), "error": str(exc)})
            try:
                dp.clear_sticky_err()
            except Exception:
                pass
            continue
        if d & S_RESET: counts["reset_st"] += 1
        if d & S_RETIRE: counts["retire_st"] += 1
        if d & S_LOCKUP: counts["lockup"] += 1
        if d & S_HALT: counts["halt"] += 1
        if i < 60 or (d & S_HALT) or (rows and rows[-1].get("dhcsr") != hex(d)) or (rows and rows[-1].get("dauth") != hex(a)):
            rows.append({"i": i, "t_ms": round((monotonic() - t0) * 1000, 3), "dhcsr": hex(d), "dauth": hex(a)})
        if d & S_HALT:
            halted = True
            break
    info[label] = {"samples": n, "elapsed_ms": round((monotonic() - t0) * 1000, 3),
                   "counts": counts, "rows": rows, "halted": halted}
    return halted

probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id="13010000003800F1047546CF0000065D")
if len(probes) != 1:
    raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
p = probes[0]
session = Session(p, auto_open=False, options={
    "no_config": True, "target_override": "cortex_m", "auto_unlock": False,
    "frequency": FREQUENCY, "resume_on_disconnect": False, "user_script": "/dev/null"})
p.open()
halted = False
try:
    p.set_clock(FREQUENCY)
    dp = DebugPort(p, session.target)
    dp.connect()
    ap = AccessPort.create(dp, APv1Address(0))
    ap.init()
    info["dp_idr"] = hex(dp.dpidr.idr) if hasattr(dp.dpidr, "idr") else str(dp.dpidr)
    info["before"] = snapshot(ap, dp)
    # Phase A: is the chip in a reset loop? Sticky S_RESET_ST/S_RETIRE_ST clear on read.
    sample_loop(ap, "phase_a_idle", 60)

    if RESET == "pin":
        # Phase B: hold nRESET, configure the debug registers while held, release and watch.
        p.assert_reset(True)
        sleep(0.05)
        info["under_reset"] = {"asserted": safe(lambda: p.is_reset_asserted())}
        try:
            dp.connect()
            ap = AccessPort.create(dp, APv1Address(0)); ap.init()
            info["under_reset"]["dp_reconnect"] = "ok"
        except Exception as exc:
            info["under_reset"]["dp_reconnect"] = str(exc)
        info["under_reset"]["read"] = {k: rd(ap, v) for k, v in (("DHCSR", DHCSR), ("DEMCR", DEMCR), ("DAUTHSTATUS", DAUTH))}
        info["under_reset"]["write"] = safe(lambda: (ap.write32(DHCSR, DBGKEY | 0x3),
                                                     ap.write32(DEMCR, (1 << 24) | (1 << 10) | 1),
                                                     dp.flush(), "ok")[-1])
        info["under_reset"]["readback"] = {k: rd(ap, v) for k, v in (("DHCSR", DHCSR), ("DEMCR", DEMCR), ("DAUTHSTATUS", DAUTH))}
        t_rel = monotonic()
        p.assert_reset(False)
        info["under_reset"]["release_ms"] = round((monotonic() - t_rel) * 1000, 3)
        halted = sample_loop(ap, "phase_b_after_pin_release", SAMPLES, halt_write=SPAM_HALT)
    elif RESET == "sysresetreq":
        info["pre_sysreset"] = {}
        info["pre_sysreset"]["write"] = safe(lambda: (ap.write32(DHCSR, DBGKEY | 0x3),
                                                      ap.write32(DEMCR, (1 << 24) | (1 << 10) | 1),
                                                      dp.flush(), "ok")[-1])
        info["pre_sysreset"]["readback"] = {k: rd(ap, v) for k, v in (("DHCSR", DHCSR), ("DEMCR", DEMCR), ("DAUTHSTATUS", DAUTH))}
        info["pre_sysreset"]["aircr_write"] = safe(lambda: (ap.write32(AIRCR, 0x05fa0004), dp.flush(), "ok")[-1])
        halted = sample_loop(ap, "phase_b_after_sysresetreq", SAMPLES, halt_write=SPAM_HALT)
    else:
        info["no_reset"] = {}
        info["no_reset"]["write"] = safe(lambda: (ap.write32(DHCSR, DBGKEY | 0x3), dp.flush(), "ok")[-1])
        halted = sample_loop(ap, "phase_b_halt_only", SAMPLES, halt_write=SPAM_HALT)

    info["after"] = snapshot(ap, dp)
    if halted:
        info["halted_registers"] = halted_regs(ap)
        info["left_halted"] = True
finally:
    p.disconnect()
    p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
out = root / ".embedder/hardware/results" / ("reset-timeline-" + RESET + "-" + stamp + ".json")
out.write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
print(json.dumps({"success": halted, "summary": "reset timeline (" + RESET + "): halted=" + str(halted)}))
'''
code = ("RESET = " + repr(reset_kind) + "\nSAMPLES = " + repr(samples) +
        "\nSPAM_HALT = " + repr(spam_halt) + "\nFREQUENCY = " + repr(frequency) + "\n" + code)
result = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(result.get("output", ""))
if result.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "reset timeline process failed; see traceback"}))
