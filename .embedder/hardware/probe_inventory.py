"""Enumerate the project pyOCD probe backend without attaching to a target."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
result = run_tool([str(root / '.venv/bin/pyocd'), 'json', '--probes'])
output = result.get('output', '')
print(output)
try:
    probes = json.loads(output).get('boards', [])
except (ValueError, TypeError):
    probes = []
expected = '13010000003800F1047546CF0000065D'
found = any(p.get('unique_id') == expected for p in probes)
print(json.dumps({'success': result.get('exit_code') == 0 and found,
                  'summary': 'Expected CMSIS-DAP probe enumerated' if found else
                  'Expected CMSIS-DAP probe was not enumerated; no target attached'}))
