#!/bin/sh
# Apply only the reviewed correction for the manifest-pinned Zephyr revision.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
zephyr="$root/.deps/zephyr"
patch="$root/patches/zephyr-cdc-session-isolation.patch"
revision=5c71a733110403a2e01f6cabd922b5f0198e9981
if [ "$(git -C "$zephyr" rev-parse HEAD)" != "$revision" ]; then
    echo 'CDC patch requires the manifest-pinned Zephyr revision; review before upgrading.' >&2
    exit 1
fi
if git -C "$zephyr" apply --reverse --check "$patch" 2>/dev/null; then
    exit 0
fi
if ! git -C "$zephyr" apply --check "$patch"; then
    echo 'CDC patch conflicts with this checkout; no files changed.' >&2
    exit 1
fi
git -C "$zephyr" apply "$patch"
