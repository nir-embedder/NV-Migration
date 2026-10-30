"""M3351KJCAE attach-only programming hook for pyOCD 0.46.0.

Use explicitly with --script, -M attach and -O load.pre_reset=off. The Nuvoton
DFP's DebugPortStart pulses nRESET even in attach mode. Replace only that step
with the standard ADIv5 power-up handshake; keep the vendor memory map/FLMs.
No device security, option-memory or protection-register writes are performed.
DIAGNOSTIC ONLY: this is not a qualified programming procedure. The initial
KI-selected attach revision reached erase but timed out in programming. The
corrected KJ selection and emulated-reset preparation below have not yet been
exercised successfully on this target. Do not use this as a recovery procedure.
"""
from pyocd.core.target import Target
from pyocd.coresight.dap import (
    DP_CTRL_STAT, CSYSPWRUPREQ, CDBGPWRUPREQ, CSYSPWRUPACK, CDBGPWRUPACK,
    MASKLANE, TRNNORMAL,
)
from pyocd.utility.timeout import Timeout


def will_init_target(target, init_sequence):
    options = target.session.options
    if (options.get('target_override') != 'm3351kjcae' or
            options.get('connect_mode') != 'attach' or
            options.get('auto_unlock') or options.get('load.pre_reset') != 'off' or
            options.get('resume_on_disconnect')):
        raise RuntimeError('Requires m3351kjcae, attach, auto_unlock=false, '
                           'load.pre_reset=off, resume_on_disconnect=false')

    def power_up_without_reset():
        dp = target.dp
        dp.write_reg(DP_CTRL_STAT, CSYSPWRUPREQ | CDBGPWRUPREQ | MASKLANE | TRNNORMAL)
        with Timeout(2.0) as timeout:
            while timeout.check():
                value = dp.read_reg(DP_CTRL_STAT)
                if value & (CSYSPWRUPACK | CDBGPWRUPACK) == (CSYSPWRUPACK | CDBGPWRUPACK):
                    return
        raise RuntimeError('Debug/system power-up handshake timed out')

    init_sequence.wrap_task('dp_init', lambda sequence:
                           sequence.replace_task('power_up_debug', power_up_without_reset))


def did_init_target(target):
    boot = target.memory_map.get_boot_memory()
    if boot.start != 0 or boot.length != 0x100000:
        raise RuntimeError('Unexpected KJCAE APROM map; refusing programming')
    if target.read32(0x40000000) != 0x03302140:
        raise RuntimeError('Unexpected M3351 PDID; refusing programming')
    if target.read32(0xe000efb8) & 0xff != 0xff:
        raise RuntimeError('Secure debug is not enabled; no unlock will be attempted')
    target.halt()
    with Timeout(2.0) as timeout:
        while timeout.check():
            if target.get_state() == Target.State.HALTED:
                break
        else:
            raise RuntimeError('Core did not halt; refusing flash algorithm execution')
    # Attach preserves the old application's SysTick/NVIC and exception state.
    # Reset core state without nRESET, which triggers the failing pack path.
    target.reset_and_halt(Target.ResetType.EMULATED)
    target.write_core_register('primask', 1)
    if target.get_state() != Target.State.HALTED:
        raise RuntimeError('Emulated reset did not leave the core halted')
