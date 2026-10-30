"""Try a supported pyOCD connect mode without invoking a flash algorithm."""
import json
from pathlib import Path
from datetime import datetime, timezone

root = Path(__file__).resolve().parents[4]
run_stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
mode = capture_profile.get('mode', 'under-reset')
frequency = int(capture_profile.get('frequency', 100000))
sequences = bool(capture_profile.get('sequences', True))
halt_after_attach = bool(capture_profile.get('halt_after_attach', False))
attach_hook = bool(capture_profile.get('attach_hook', False))
disable_start = bool(capture_profile.get('disable_start', False))
if disable_start and (mode != 'under-reset' or attach_hook or not sequences):
    raise ValueError('Disable only DebugPortStart during standard under-reset diagnostic')
suffix = '-without-port-start' if disable_start else ''
if mode not in ('under-reset', 'pre-reset', 'attach') or frequency not in (100000, 1000000):
    raise ValueError('Unsupported diagnostic profile')
code = r'''
import json
import logging
from pathlib import Path
from pyocd.core.helpers import ConnectHelper
logging.basicConfig(level=logging.DEBUG)
root = Path.cwd()
info = {"mode": MODE, "frequency": FREQUENCY, "pack_sequences": SEQUENCES,
        "selected_pack_target": "m3351kjcae",
        "disabled_sequences": ['DebugPortStart'] if DISABLE_START else []}
s = ConnectHelper.session_with_chosen_probe(
    unique_id="13010000003800F1047546CF0000065D", blocking=False,
    options={"project_dir": str(root), "target_override": "m3351kjcae",
             "no_config": True,
             "pack": str(root / '.deps/packs/Nuvoton.NuMicroM33_DFP.1.0.6.pack'),
             "connect_mode": MODE, "frequency": FREQUENCY,
             "reset_type": "hardware", "auto_unlock": False,
             "resume_on_disconnect": False, "cache.enable_memory": False,
             "pack.debug_sequences.enable": SEQUENCES, "debug.traceback": True,
             "pack.debug_sequences.disabled_sequences": ['DebugPortStart'] if DISABLE_START else [],
             "user_script": str(root / 'tools/pyocd_attach.py') if ATTACH_HOOK else '/dev/null',
             "load.pre_reset": "off"})
if s is None:
    raise RuntimeError('Expected probe not found')
try:
    with s:
        t = s.target
        info["state_before_halt"] = str(t.get_state())
        info["auth_before_halt"] = hex(t.read32(0xe000efb8))
        if HALT_AFTER_ATTACH:
            t.halt()
            s.probe.flush()
        info["state"] = str(t.get_state())
        for name, addr in (("DHCSR", 0xe000edf0), ("DAUTHSTATUS", 0xe000efb8),
                           ("DSCSR", 0xe000ee08), ("SYS_PDID", 0x40000000),
                           ("SYS_RSTSTS", 0x40000004), ("SYS_SRAM_STATUS", 0x400000c4),
                           ("SCU_FNSADDR", 0x4002f02c), ("FMC_APWPROT0", 0x4000c110)):
            try:
                info[name] = hex(t.read32(addr))
            except Exception as exc:
                info[name] = {"error": str(exc)}
        info["memory_map"] = [{"name": r.name, "start": hex(r.start), "length": hex(r.length)} for r in t.memory_map]
        if str(t.get_state()) == 'State.HALTED':
            info['core_registers'] = {}
            for name in ('pc', 'lr', 'sp', 'msp', 'psp', 'msplim', 'psplim', 'control', 'xpsr', 'primask', 'basepri', 'faultmask'):
                try:
                    info['core_registers'][name] = hex(t.read_core_register(name))
                except Exception as exc:
                    info['core_registers'][name] = str(exc)
except Exception as exc:
    info["error"] = str(exc)
finally:
    (root / ('.embedder/hardware/results/connect-kj-' + MODE + ('-without-port-start' if DISABLE_START else '') + ('-no-sequences' if not SEQUENCES else '') + ('-halt' if HALT_AFTER_ATTACH else '') + '-' + RUN_STAMP + '.json')).write_text(json.dumps(info, indent=2)+'\n')
print(json.dumps(info, indent=2))
print(json.dumps({"success": info.get('state') == 'State.HALTED',
                  "summary": 'Non-erasing exact-target connection diagnostic, mode=' + MODE}))
'''
code = 'RUN_STAMP = ' + repr(run_stamp) + '\nMODE = ' + repr(mode) + '\nFREQUENCY = ' + str(frequency) + '\nSEQUENCES = ' + repr(sequences) + '\nHALT_AFTER_ATTACH = ' + repr(halt_after_attach) + '\nATTACH_HOOK = ' + repr(attach_hook) + '\nDISABLE_START = ' + repr(disable_start) + '\n' + code
result = run_tool([str(root / '.venv/bin/python'), '-c', code])
log = root / ('.embedder/hardware/results/connect-kj-' + mode + suffix + ('-no-sequences' if not sequences else '') + ('-halt' if halt_after_attach else '') + '-' + run_stamp + '.log')
log.write_text(result.get('output', ''))
print(result.get('output', ''))
if result.get('exit_code') != 0:
    print(json.dumps({'success': False, 'summary': 'Non-erasing connect diagnostic failed; see saved full log'}))
