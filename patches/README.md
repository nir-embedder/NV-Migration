# Local pinned-SDK corrections

`zephyr-cdc-session-isolation.patch` applies only to Zephyr
`5c71a733110403a2e01f6cabd922b5f0198e9981` (the west manifest revision).
It changes the existing next-stack CDC ACM implementation and adds the optional
session callback declaration at `include/zephyr/usb/class/usbd_cdc_acm.h`.
It does not replace the driver or modify Modbus runtime code.

```sh
sh patches/apply.sh
```

`tools/build.sh` and `tests/cdc/run.sh` call this automatically. A clean checkout
is patched; an already-patched checkout is left alone. A changed revision,
partial application or conflicting local edit fails rather than overwriting it.
The check/apply uses Git's atomic patch application, not fuzzy patch matching.
Review and rebase the patch explicitly before changing the manifest revision.
Do not commit the ignored SDK checkout instead of this patch.

The callback extends the pinned SDK API; upstream does not provide it. Register
it before USB enable and do not wait for work on the CDC queue from it. Existing
UART APIs and descriptors are retained. See the CDC reconnect section in
[docs/migration.md](../docs/migration.md) for the admission/ownership contract,
and [tests/cdc](../tests/cdc/README.md) for executable driver regressions.
