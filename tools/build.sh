#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
profile=${1:-server}
case "$profile" in
  server|client|separate|large) ;;
  *) echo 'usage: tools/build.sh [server|client|separate|large]' >&2; exit 2 ;;
esac
extra="$root/config/server.conf"
case "$profile" in
  client) extra="$root/config/client.conf" ;;
  separate) extra="$extra;$root/config/separate-regions.conf" ;;
  large) extra="$extra;$root/config/large-buffer.conf" ;;
esac
if [ -f "$root/config/usb-identity.conf" ]; then
  extra="$extra;$root/config/usb-identity.conf"
else
  echo 'No assigned USB identity: compile-only build; firmware will refuse USB startup.' >&2
fi
sh "$root/patches/apply.sh"
export PATH="$root/.venv/bin:$PATH"
export ZEPHYR_BASE="$root/.deps/zephyr"
export ZEPHYR_SDK_INSTALL_DIR="$root/.toolchains/zephyr-sdk-1.0.1"
exec "$root/.venv/bin/west" build -b numaker_m3351ki/m335xxx \
  -d "$root/build/$profile" "$root" -- -DEXTRA_CONF_FILE="$extra"
