"""Release the original application with a hardware reset, without target init."""
from pathlib import Path

root = Path(__file__).resolve().parents[4]
code = r'''
import json
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.probe.debug_probe import DebugProbe

probes = ConnectHelper.get_all_connected_probes(
    blocking=False, unique_id="13010000003800F1047546CF0000065D")
if len(probes) != 1:
    raise RuntimeError("Expected unique CMSIS-DAP probe")
p = probes[0]
# Session provides CMSIS-DAP options, but is never opened: no target initialization.
session = Session(p, auto_open=False, options={"no_config": True, "auto_unlock": False})
p.open()
try:
    p.connect(DebugProbe.Protocol.SWD)
    try:
        p.reset()
    finally:
        p.disconnect()
finally:
    p.close()
print(json.dumps({"success": True, "summary": "Hardware reset pulse completed; no flash, core initialization, unlock, or security changes"}))
'''
result = run_tool([str(root / '.venv/bin/python'), '-c', code])
print(result.get('output', ''))
if result.get('exit_code') != 0:
    print('{"success": false, "summary": "Hardware reset pulse failed; no flash operation requested"}')
