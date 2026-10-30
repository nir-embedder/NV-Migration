"""Open the Nu-Link VCOM (UART0 diagnostics) first, release the target to boot
(boot_release.py: clear debug enables, DP down, one nRESET pulse), then capture
UART0 output and poll the macOS USB inventory for the application's J3 CDC
device (0416:b002). No flash/config/security writes.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
seconds = int(capture_profile.get("seconds", 8))
release = capture_profile.get("release", "boot_release.py")
if release not in ("boot_release.py", "resume_release.py"):
    raise ValueError("release must be boot_release.py or resume_release.py")
code = r'''
import json, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path
from time import monotonic, sleep
import serial
root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
from flash import passive_usb_inventory

PROBE = "13010000003800F1047546CF0000065D"
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE, "stage": "inventory"}
devs = [d for d in passive_usb_inventory()["devices"] if d["vid"] == 0x0416 and d["pid"] == 0x2004 and d["serial"] == PROBE]
if len(devs) != 1 or len(devs[0]["ports"]) != 1:
    raise RuntimeError("Expected exactly one identity-matched Nu-Link VCOM port")
path = devs[0]["ports"][0]
info["vcom_port"] = path
info["stage"] = "serial_open"
port = serial.Serial(path, baudrate=115200, bytesize=8, parity="N", stopbits=1, timeout=0.2, exclusive=True)
port.dtr = True
port.reset_input_buffer()
try:
    info["stage"] = "release"
    r = subprocess.run([sys.executable, str(root / ".embedder/hardware/cases/m3351-flash-lockup" / RELEASE)],
                       capture_output=True, text=True, timeout=60)
    info["release_exit"] = r.returncode
    info["release_stdout_tail"] = r.stdout[-1500:]
    info["release_stderr_tail"] = r.stderr[-1500:]
    if r.returncode != 0:
        print(json.dumps(info, indent=2))
        raise RuntimeError("release script failed")
    info["stage"] = "observe"
    buf = b""
    seen = []
    t0 = monotonic()
    next_inv = 1.0
    while monotonic() - t0 < SECONDS:
        buf += port.read(4096)
        if monotonic() - t0 >= next_inv:
            next_inv += 1.0
            inv = [d for d in passive_usb_inventory()["devices"] if d["vid"] == 0x0416 and d["pid"] == 0xB002]
            if inv:
                seen = inv
    info["uart_bytes"] = len(buf)
    info["uart_text"] = buf.decode("utf-8", "replace")
    info["app_usb_device"] = seen[0] if seen else None
    info["stage"] = "done"
finally:
    port.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"boot-observe-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
ok = info.get("stage") == "done" and (info.get("uart_bytes", 0) > 0 or info.get("app_usb_device"))
print(json.dumps({"success": bool(ok), "summary": "boot: uart_bytes=%s app_usb=%s" % (info.get("uart_bytes"), bool(info.get("app_usb_device")))}))
'''
code = "SECONDS = %d\nRELEASE = %r\n" % (seconds, release) + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "boot/observe did not complete"}))
