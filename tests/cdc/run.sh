#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
sh "$root/patches/apply.sh"
export PATH="$root/.venv/bin:$PATH"
export ZEPHYR_BASE="$root/.deps/zephyr"
export ZEPHYR_SDK_INSTALL_DIR="$root/.toolchains/zephyr-sdk-1.0.1"
qemu=${QEMU_BIN:-$(command -v qemu-system-arm)}
for queue in system dedicated; do
    dedicated=OFF
    [ "$queue" != dedicated ] || dedicated=ON
    "$root/.venv/bin/west" build -b qemu_cortex_m3 \
        -d "$root/tests/cdc/build-$queue" "$root/tests/cdc" -- \
        -DCDC_DEDICATED_WORKQUEUE="$dedicated"
    "$root/.venv/bin/python" "$root/tests/zephyr/run_qemu.py" \
        "$root/tests/cdc/build-$queue/zephyr/zephyr.elf" --qemu "$qemu"
done
