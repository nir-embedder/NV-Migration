"""ROM UART ISP entry via a real nRESET pulse while the sync stream is running.

TRM: lockup is a warm reset (user code restarts); the MaskROM/ISP only runs
after a cold reset (nRESET pin, POR, CHIP, LVR, BOD). VCOM BREAK does not reset
the target. So: power the DP down (ICE not "connected"), keep the CMSIS-DAP
probe open for pin control only, stream 62 x 'a' on the Nu-Link VCOM, and
pulse nRESET so the ROM boot window overlaps the stream. On 'A', identify (A0)
and read CONFIG words with the audited adapter. No halt, no DP power-up after
the pulse, no erase/program/config/security writes.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
attempts = int(capture_profile.get("attempts", 6))
baud = int(capture_profile.get("baud", 115200))
hold_ms = int(capture_profile.get("hold_ms", 20))
window_ms = int(capture_profile.get("window_ms", 700))
if not 1 <= attempts <= 20 or baud not in (115200, 230400, 460800, 921600):
    raise ValueError("unsupported profile")
code = r'''
import json, struct, sys, threading
from datetime import datetime, timezone
from pathlib import Path
from time import monotonic, sleep
import serial
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address
from pyocd.probe.debug_probe import DebugProbe

root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
from flash import passive_usb_inventory
from bootloader_protocol import BootloaderUartSession, CONFIG_BASE

PROBE = "13010000003800F1047546CF0000065D"
result = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE, "baud": BAUD,
          "attempts_requested": ATTEMPTS, "hold_ms": HOLD_MS, "window_ms": WINDOW_MS,
          "scope": "DP power-down, nRESET pin pulse, UART sync/identify/CONFIG read; no halt, no writes",
          "stage": "init", "success": False, "attempts": []}
port = None
probe = None
stop = threading.Event()
synced = threading.Event()
stream_stats = {"bursts": 0, "rx": b""}

def streamer():
    while not stop.is_set() and not synced.is_set():
        port.write(b"a" * 62)
        port.flush()
        stream_stats["bursts"] += 1
        got = port.read(1)
        if got:
            stream_stats["rx"] += got
            if got == b"A":
                synced.set()
                return

try:
    # 1. probe: SWD pin control only; make sure DP debug power is released
    result["stage"] = "probe_open"
    probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id=PROBE)
    if len(probes) != 1:
        raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
    probe = probes[0]
    session = Session(probe, auto_open=False, options={
        "no_config": True, "target_override": "cortex_m", "auto_unlock": False,
        "frequency": 1000000, "resume_on_disconnect": False})
    probe.open()
    probe.connect(DebugProbe.Protocol.SWD)
    dp = DebugPort(probe, session.target)
    dp.connect()
    result["ctrl_stat_connected"] = hex(dp.read_reg(DP_CTRL_STAT))
    dp.power_down_debug()
    result["ctrl_stat_powered_down"] = hex(dp.read_reg(DP_CTRL_STAT))
    # 2. VCOM
    result["stage"] = "serial_open"
    devices = [d for d in passive_usb_inventory()["devices"]
               if d["vid"] == 0x0416 and d["pid"] == 0x2004 and d["serial"] == PROBE]
    if len(devices) != 1 or len(devices[0]["ports"]) != 1:
        raise RuntimeError("Expected one identity-matched Nu-Link VCOM")
    path = devices[0]["ports"][0]
    result["port"] = path
    port = serial.Serial(port=None, baudrate=BAUD, bytesize=8, parity="N", stopbits=1,
                         timeout=0.003, write_timeout=1.0, rtscts=False, dsrdtr=False,
                         xonxoff=False, exclusive=True)
    port.dtr = True
    port.rts = False
    port.port = path
    port.open()
    port.reset_input_buffer()
    # 3. stream + nRESET pulses
    result["stage"] = "sync"
    t = threading.Thread(target=streamer, daemon=True)
    t.start()
    sleep(0.05)
    for attempt in range(ATTEMPTS):
        rec = {"attempt": attempt, "bursts_before": stream_stats["bursts"]}
        t0 = monotonic()
        probe.assert_reset(True)
        sleep(HOLD_MS / 1000.0)
        probe.assert_reset(False)
        rec["released_ms"] = round((monotonic() - t0) * 1000, 1)
        deadline = monotonic() + WINDOW_MS / 1000.0
        while monotonic() < deadline and not synced.is_set():
            sleep(0.005)
        rec["bursts_after"] = stream_stats["bursts"]
        rec["synced"] = synced.is_set()
        rec["rx_so_far"] = stream_stats["rx"].hex()
        rec["elapsed_ms"] = round((monotonic() - t0) * 1000, 1)
        result["attempts"].append(rec)
        if synced.is_set():
            break
    stop.set()
    t.join(1.0)
    result["synchronized"] = synced.is_set()
    if not synced.is_set():
        raise TimeoutError("no 'A' from ROM after nRESET pulses")
    port.timeout = 1.0
    sleep(0.02)
    result["bytes_after_sync"] = port.read(64).hex()
    protocol = BootloaderUartSession(port, expected_pdid=0x03302140)
    protocol._synchronized = True
    result["stage"] = "identify"
    identity = protocol.connect()
    result["identity_words"] = [hex(w) for w in identity.words]
    result["pdid"] = hex(identity.pdid)
    result["stage"] = "config_read"
    cfg = {}
    for i in (0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14):
        try:
            cfg["CONFIG%d" % i] = hex(protocol.read_config_word(CONFIG_BASE + 4 * i))
        except Exception as exc:
            cfg["CONFIG%d" % i] = "error: %s: %s" % (type(exc).__name__, exc)
            break
    result["config"] = cfg
    result["success"] = True
    result["stage"] = "done"
except (Exception, KeyboardInterrupt) as exc:
    stop.set()
    result["error"] = "%s: %s" % (type(exc).__name__, exc)
finally:
    if port is not None:
        try:
            port.close()
        except Exception as exc:
            result["close_error"] = "%s: %s" % (type(exc).__name__, exc)
    if probe is not None:
        try:
            probe.disconnect()
            probe.close()
        except Exception as exc:
            result["probe_close_error"] = "%s: %s" % (type(exc).__name__, exc)
    out = root / ".embedder/hardware/results" / ("rom-uart-nreset-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json")
    out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    print(json.dumps({"success": result["success"], "summary": "ROM UART via nRESET pulse: " + result["stage"] + (" synced" if result.get("synchronized") else " no sync")}))
'''
code = "ATTEMPTS = %d\nBAUD = %d\nHOLD_MS = %d\nWINDOW_MS = %d\n" % (attempts, baud, hold_ms, window_ms) + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "nRESET UART sync process failed; no programming requested"}))
