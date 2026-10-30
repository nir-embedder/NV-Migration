#!/usr/bin/env python
"""Resume a debug-halted running application and detach: clear C_HALT and
C_DEBUGEN (DHCSR write only), power the DP down, no reset. Standalone script.
"""
import json
from datetime import datetime, timezone
from pathlib import Path

from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address
from pyocd.probe.debug_probe import DebugProbe

PROBE = "13010000003800F1047546CF0000065D"
DHCSR, DEMCR = 0xE000EDF0, 0xE000EDFC
root = Path(__file__).resolve().parents[4]
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
        "method": "DHCSR resume + debug disable, DP power-down; no reset"}
probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id=PROBE)
if len(probes) != 1:
    raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
p = probes[0]
s = Session(p, auto_open=False, options={"no_config": True, "target_override": "cortex_m",
                                         "auto_unlock": False, "frequency": 1000000,
                                         "resume_on_disconnect": False})
p.open()
p.connect(DebugProbe.Protocol.SWD)
dp = DebugPort(p, s.target)
try:
    dp.connect()
    ap = AccessPort.create(dp, APv1Address(0))
    ap.init()
    info["before"] = {"DHCSR": hex(ap.read32(DHCSR)), "DEMCR": hex(ap.read32(DEMCR))}
    ap.write32(DEMCR, 0)
    ap.write32(DHCSR, 0xA05F0000)
    p.flush()
    info["after"] = {"DHCSR": hex(ap.read32(DHCSR)), "DEMCR": hex(ap.read32(DEMCR))}
    dp.power_down_debug()
    info["ctrl_stat_down"] = hex(dp.read_reg(DP_CTRL_STAT))
finally:
    p.disconnect()
    p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"resume-release-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
