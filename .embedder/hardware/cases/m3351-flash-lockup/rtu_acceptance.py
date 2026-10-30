"""Run the project's Modbus RTU interoperability check against the native J3
CDC ACM port of the programmed server build (unit 10, shared 16-word banks,
128-byte ADU). Uses tools/modbus_verify.py unchanged; the port is identity
matched by VID/PID/serial, never hardcoded. No flashing, no reset.
"""
import json
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[4]
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
out = root / ".embedder/hardware/results" / f"rtu-acceptance-{stamp}.json"
duration = str(capture_profile.get("duration", 20))
iterations = str(capture_profile.get("iterations", 1))
res = run_tool([str(root / ".venv/bin/python"), str(root / "tools/modbus_verify.py"),
                "--transport", "rtu", "--profile", "shared", "--buffer-size", "128",
                "--unit", "10", "--vid", "0x0416", "--pid", "0xb002",
                "--usb-serial", "00010031047B4B1F00000003",
                "--duration", duration, "--iterations", iterations,
                "--json", str(out), "board-server"])
print(res.get("output", ""))
ok = res.get("exit_code") == 0 and out.is_file()
print(json.dumps({"success": ok, "summary": "RTU acceptance exit=%s result=%s" % (res.get("exit_code"), out.name if ok else None)}))
