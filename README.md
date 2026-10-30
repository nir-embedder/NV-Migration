# NV-Migration: Modbus on NK-M3351KI / Zephyr

A port of **alejoseb/Modbus-STM32-HAL-FreeRTOS** to Nuvoton M3351 and native
Zephyr services. It retains the upstream-derived protocol/data-model logic for
FC1/2/3/4/5/6/15/16, with client/master and server/slave roles over:

- **RTU over native USB CDC ACM**, using Zephyr's interrupt UART API.
- **TCP over native USB CDC ECM**, using Zephyr IPv4 sockets.

This is not Zephyr's Modbus subsystem. The portable protocol core has no Zephyr
or hardware dependencies; scheduling, streams and USB/networking are separate.

> **Acceptance boundary:** host protocol tests are available and passing results
> are recorded in [their README](tests/protocol/README.md). That does not establish
> physical operation. Probe communication and a partial 512 KiB APROM backup have
> been established. The confirmed KJ chip has 1 MiB APROM; earlier attempts used
> the wrong KI target selection. The first attempt reported LOCKUP/RAM FAULT.
> A second attempt erased application sectors and timed out during programming;
> **APROM is now incomplete**, and the original backup remains preserved.
> Successful programming, boot and native ACM+ECM runtime acceptance are **not
> established**. Do not run an unreviewed `west flash`, generic runner, mass erase
> or replacement load based on a successful build. `docs/validation.md` records
> the latest build, test and hardware evidence and the pending recovery boundary.

## Repository and pinned inputs

| Path | Purpose |
| --- | --- |
| `lib/modbus/Inc/ModbusCore.h`, `Src/ModbusCore.c` | Portable upstream-derived PDUs, memory maps, CRC and RTU length inference |
| `lib/modbus/Inc/Modbus.h`, `Src/Modbus.c` | Zephyr lifecycle, bounded requests and caller-owned completion |
| `lib/modbus/Src/ModbusRtu.c`, `ModbusTcp.c` | Bounded UART/CDC and TCP stream adapters |
| `src/` | Native composite USB, private IPv4 configuration and demo applications |
| `boards/numaker_m3351ki.overlay` | Confirmed KJ standalone memory layout and ACM/ECM devices |
| `config/`, `tools/build.sh` | Server, client, separate-map and large-buffer build profiles |
| `tests/protocol/`, `tests/zephyr/`, `tests/tools/` | Portable C, emulated Zephyr and host verification-tool tests |
| `tools/modbus_verify.py` | Explicitly invoked PC interoperability checks; never a flasher or network configurator |

The immutable library source revision is
`9c022fd2538edb5b53e2e07c98ebbe9a4685546c`. [west.yml](west.yml) pins Zephyr to
`5c71a733110403a2e01f6cabd922b5f0198e9981` and pins its CMSIS/CMSIS_6/Nuvoton HAL
inputs individually. The selected SDK is **Zephyr SDK 1.0.1, GNU ARM**.
[requirements-build.txt](tools/requirements-build.txt) pins **west 1.5.0** and
**pyOCD 0.46.0**, then includes the pinned Zephyr checkout's base requirements.
Those Zephyr Python requirements contain version ranges: this is not a complete
transitive Python lock or a claim of bit-identical host environments.

## 1. Host prerequisites — macOS Apple Silicon

Run the following sections from this repository's root, not from `.deps/zephyr`.
The existing prepared workspace may already have `.venv`, `.west`, `.deps` and
`.toolchains`; inspect/reuse them rather than overwriting working installations.
Only the portable C tests can run without the Zephyr/bootstrap steps.

Required: Xcode Command Line Tools, Git, **Python 3.12+**, CMake **3.28+**, Ninja,
dtc **1.4.6+**, gperf and the SDK below. Homebrew QEMU is needed for the emulated
Zephyr tests; SDK macOS host tools do not supply that test executable here.
The project Python environment was prepared with Python 3.12.16.

With Homebrew already installed, install **only missing** prerequisites:

```sh
xcode-select -p
# If command-line tools are absent, run: xcode-select --install
brew install cmake ninja dtc gperf python@3.12
# Optional, for the Zephyr emulated tests:
brew install qemu

/usr/bin/clang --version
cmake --version
ninja --version
dtc --version
"$(brew --prefix python@3.12)/bin/python3.12" --version
```

These are user-run bootstrap commands, not hardware operations. Installing
OpenOCD or pyOCD is not evidence that its flash algorithm supports this board.
See the official [Zephyr host prerequisites](https://docs.zephyrproject.org/latest/develop/getting_started/index.html)
for Homebrew installation details and other host platforms.

## 2. Python and the project-root west workspace

For a fresh checkout/extracted project with no `.venv` yet:

```sh
"$(brew --prefix python@3.12)/bin/python3.12" -m venv .venv
. .venv/bin/activate
python -m pip install west==1.5.0
```

For an existing environment, activate it and check `python --version` and
`west --version` before deciding whether it needs replacement.

### Important: `.west` belongs inside this repository

This manifest uses `self.path: .`; dependencies belong in this root's `.deps/`.
**Do not use `west init -l .` for this layout**: local initialization normally
places `.west` next to the manifest directory, making the parent directory the
workspace. That would put dependencies outside this project.

For a **fresh root with no `.west` directory**, explicitly create the local
workspace configuration using west's configuration command:

```sh
(
  set -eu
  test -f west.yml
  mkdir .west
  west config --local manifest.path .
  west config --local manifest.file west.yml
  west config --local zephyr.base .deps/zephyr
)
```

Do not replace an existing `.west/config` blindly. Its intended content is:

```ini
[manifest]
path = .
file = west.yml
[zephyr]
base = .deps/zephyr
```

Verify the root and manifest, then fetch the pinned dependencies:

```sh
west topdir
west config --local manifest.path
# Expected: this repository's absolute root, then a single dot.
west update
python -m pip install -r tools/requirements-build.txt
python -m pip check
west list -f '{name}: {revision} -> {path}'
```

The requirements file references `.deps/zephyr`, so install it **after**
`west update`. On an existing workspace, preserve any local dependency changes
before updating; do not delete another workspace's `.west` to repair a path.
The optional `.deps/modbus-upstream` provenance checkout is not required to build
the already-ported library.

## 3. SDK 1.0.1 in the project-local path

The build helper expects:

```text
.toolchains/zephyr-sdk-1.0.1/
  sdk_version
  setup.sh
  gnu/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc
```

If this installation already exists, skip extraction and check it:

```sh
cat .toolchains/zephyr-sdk-1.0.1/sdk_version
.toolchains/zephyr-sdk-1.0.1/gnu/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc --version
```

For a fresh Apple Silicon installation, use the official **minimal** bundle
plus the ARM GNU archive. The commands below download and checksum both before
extraction; do not extract over an existing SDK directory:

```sh
mkdir -p .toolchains
(
  set -eu
  cd .toolchains
  test ! -e zephyr-sdk-1.0.1
  release=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v1.0.1
  bundle=zephyr-sdk-1.0.1_macos-aarch64_minimal.tar.xz
  arm=toolchain_gnu_macos-aarch64_arm-zephyr-eabi.tar.xz
  curl --fail --location --remote-name "$release/$bundle"
  curl --fail --location --remote-name "$release/$arm"
  curl --fail --location --output sha256.sum "$release/sha256.sum"
  grep -F "  $bundle" sha256.sum | shasum -a 256 --check -
  grep -F "  $arm" sha256.sum | shasum -a 256 --check -
  tar -xf "$bundle"
  mkdir -p zephyr-sdk-1.0.1/gnu
  tar -xf "$arm" -C zephyr-sdk-1.0.1/gnu
  bash zephyr-sdk-1.0.1/setup.sh -t arm-zephyr-eabi -c
)
```

`setup.sh -c` registers the SDK with CMake; `-t` skips downloading the already
extracted ARM toolchain. Rerun SDK setup if the directory is relocated. The
[official release checksums](https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v1.0.1/sha256.sum)
for these assets are:

- Minimal bundle: `867063901f39528a6175a80ebc20367bd6cb440593e7e2650eda30392f1f6b65`
- ARM GNU archive: `4008edb5d4840cd994aedd7f1309bfb63e7243729d57839ebf1cc83c1f17c886`

The official [SDK instructions](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html)
also offer a larger full GNU bundle. The project needs the ARM toolchain, not
all architectures. No udev setup is required on macOS.

## 4. Build the application — no flashing

```sh
sh tools/build.sh server
sh tools/build.sh client
sh tools/build.sh separate
sh tools/build.sh large
```

The helper selects `numaker_m3351ki/m335xxx`, uses the project Python/SDK paths,
and creates independent outputs:

| Profile | Application | Map | Nominal RTU capacity | Output directory |
| --- | --- | --- | ---: | --- |
| `server` | RTU + TCP server | Two independent 16-word shared banks | 128 | `build/server` |
| `client` | RTU + TCP client demo | Queries the shared-map PC servers | 128 | `build/client` |
| `separate` | RTU + TCP server | Independent coils/DI/HR/IR regions | 128 | `build/separate` |
| `large` | RTU + TCP server | Two independent 128-word shared banks | 256 | `build/large` |

Artifacts are under each output's `zephyr/`: `zephyr.elf`, `zephyr.bin`,
`zephyr.dts`, `zephyr.map` and `.config`. Inspect the merged DTS/config/map, not
just the source overlay, before any separately reviewed programming operation.
If changing cached board/configuration requires a pristine build, use a new build
directory or deliberately regenerate the relevant profile; do not erase unrelated
outputs as a troubleshooting shortcut.

### USB identity is an explicit local input

The firmware's VID/PID defaults remain **zero**. A zero value permits compile
checks but makes USB initialization fail and stops the application handlers.
The helper automatically appends `config/usb-identity.conf` when present; that
file is ignored by Git and is not supplied by a fresh checkout.

For this isolated bench demonstration, the user explicitly requested use of an
existing development configuration. The selected local identity is
**`0416:B002`**, taken from Nuvoton's **M3351 BSP V3.00.002
`USBD_VCOM_SerialEmulator`** example. The local file contains:

```conf
# Isolated bench demonstration only; not a production allocation.
CONFIG_APP_USB_VID=0x0416
CONFIG_APP_USB_PID=0xb002
```

This records the selected sample provenance and user instruction, **not a
manufacturer grant, VID ownership or production PID allocation**. Nuvoton advises
customer applications to use their own IDs. Zephyr's `2fe3:0001` sample identity
has sample-only restrictions and was not selected. The backed-up original
firmware's HID identity, `0416:B001`, was also **not reused**. Copying an example
VID/PID does not make this ACM+ECM composite the vendor's original VCOM example.

Keep the development identity in the ignored local overlay only; do not promote
it into shipped defaults or distribute/ship a product with it. Obtain appropriate
USB identifiers and permissions before production. Rebuild the chosen profile
after adding/changing the local file and record the actual configuration in the
validation evidence. Selecting these IDs does not resolve the reset/halt fault:
**the migrated demonstration has not been flashed or accepted on hardware**.

### Confirmed KJ flash size and boot layout

The user confirmed the MCU is **M3351KJCAE**, with **1 MiB APROM** and 128 KiB
SRAM, despite the NuMaker M3351KI board name. The build retains the upstream KJ
flash map. The overlay removes unused MCUboot partitions and the chosen code
partition; `prj.conf` disables DT code-partition use. The application boots
directly from **APROM address/offset 0**. `pyocd.yaml` selects `m3351kjcae` from
Nuvoton's DFP, which provides `M3351_AP_1M.FLM`.

Earlier attempts incorrectly selected the 512 KiB KI device and its FLM. The
preserved 512 KiB backup covers **only the lower half of KJ APROM**; the upper
half was not backed up. That target mismatch is confirmed, but it is not yet
proven to explain the programming HardFault/timeout. Correcting the selection
does not make the experimental attach hook a validated recovery procedure.
Programming remains blocked pending safe access to the incomplete image; this
README supplies no blind flash/erase command.

### Adapted flasher and macOS inspection

The user-supplied guarded `flash.py` is adapted at `tools/flash.py` for this
workspace and the confirmed **KJ** part. It does not use the attachment's nested
workspace paths, Hello World default, KI target or 512-KiB preservation limit.
See [EMBEDDER.md](EMBEDDER.md) for current project instructions.

```sh
# Offline only, also the default mode when --program is absent:
.venv/bin/python tools/flash.py --build-dir build/server --dry-run
# OS enumeration only: does not open a probe, serial port or target USB interface:
.venv/bin/python tools/flash.py --list-usb
```

Offline validation requires an exact ELF/binary match using allocated ELF
sections and Zephyr's `objcopy --gap-fill 0xFF` convention, including alignment
gaps inside load segments. It checks vectors, runtime/load bounds and the
pinned DFP/FLM hashes. `--pack` or `NUVOTON_DFP` may select the audited local
pack explicitly; nothing is downloaded. A dry run is **not programming or HIL**.

Live mode requires explicit `--program` and the full `--probe` ID and must run
through the hardware-arbitrated flash tool. **Do not run it against the current
unrecovered board:** implementing the adapter does not establish a supported
recovery entry. It retains fail-closed authentication/protection/context checks,
requires stable full-1-MiB APROM and other-region backups, preserves the last
partial sector, and requests neither reset nor unlock. It still initializes
debug hardware and executes a RAM algorithm, so it is not passive or atomic.
The old 512-KiB backup is never accepted as full KJ preservation evidence.

## 5. Tests without a physical target

### Portable C core: Clang ASAN + UBSAN

These need only the host compiler, CMake and Ninja:

```sh
cmake -S tests/protocol -B tests/protocol/build -G Ninja \
  -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_BUILD_TYPE=Debug \
  -DMODBUS_SANITIZERS=ON
cmake --build tests/protocol/build
ctest --test-dir tests/protocol/build --output-on-failure
```

The ten suites cover every FC, maps, quantity/capacity limits, malformed frames,
response matching, canaries, CRC and length inference. See
[tests/protocol/README.md](tests/protocol/README.md) for recorded results,
coverage and additional commands. A host pass is not USB or target acceptance.

### Host verification-tool tests

```sh
. .venv/bin/activate
python -m pip install -r requirements-test.txt
python -m pip check
python -m pytest -q tests/tools
```

[requirements-test.txt](requirements-test.txt) pins PyModbus 3.16.1, pyserial 3.5
and pytest 9.2.0. These tests use local loopback/fake or host-emulated serial
transports, not the board. They do not configure the host network or flash it.
The CLI rejects unverified PyModbus/pyserial versions.

### Zephyr runtime and stream tests in QEMU

These use `qemu_cortex_m3` for software tests, **not** an M3351/USB hardware model.
After the Zephyr/SDK bootstrap and Homebrew QEMU installation:

```sh
export PATH="$PWD/.venv/bin:$PATH"
export ZEPHYR_BASE="$PWD/.deps/zephyr"
export ZEPHYR_SDK_INSTALL_DIR="$PWD/.toolchains/zephyr-sdk-1.0.1"
export QEMU_BIN_PATH="$(brew --prefix qemu)/bin"
qemu-system-arm --version

west build -b qemu_cortex_m3 -d build/ztest-rtu tests/zephyr
west build -d build/ztest-rtu -t run

west build -b qemu_cortex_m3 -d build/ztest-rtu-large tests/zephyr -- \
  -DCONFIG_MODBUS_PORT_BUFFER_SIZE=256
west build -d build/ztest-rtu-large -t run

west build -b qemu_cortex_m3 -d build/ztest-tcp tests/zephyr -- \
  -DEXTRA_CONF_FILE=tcp.conf
west build -d build/ztest-tcp -t run
```

These configurations correspond to [tests/zephyr/testcase.yaml](tests/zephyr/testcase.yaml).
Consult `docs/validation.md` for actual execution results and remaining cases;
the presence of these commands is not a claim that every runtime gate passed.
No board, CMSIS-DAP connection or live USB interface is needed for these tests.

## 6. Physical connections and private network — acceptance pending

- **J3:** target native USB data connection, intended to expose ACM serial and
  ECM Ethernet together after successful programming, boot and USB setup.
- **ICEJ2:** Nu-Link/debug connection, separate from the application's native
  USB. The connected probe is being handled through the reviewed CMSIS-DAP
  programming/debug workflow; do not select a probe merely by a serial-port name.
- **Diagnostics:** upstream UART0, separate from the binary ACM Modbus channel.
  A probe VCOM, if available, is not the native Modbus endpoint.
- Neither opening a terminal nor DTR assertion is a startup prerequisite for
  TCP. Do not attach a text console to the binary Modbus ACM stream.

The application defaults are:

| Setting | Value |
| --- | --- |
| Board ECM IPv4 | `192.168.77.2/24` |
| PC ECM IPv4 / client peer | `192.168.77.1/24` |
| Gateway | None |
| Board server units | RTU **10**, TCP **1** |
| Board TCP server | Port **502** |
| PC TCP server for board-client demo | `192.168.77.1:1502` |

Before configuring the PC, identify the newly enumerated ECM interface and check
that `192.168.77.0/24` does not conflict with existing networks/VPNs. Configure
only that isolated interface after approval. Do **not** change the Mac's default
route, gateway, Wi-Fi configuration or an unrelated Ethernet interface. There is
no automatic host-network setup in the firmware or verification tool; never
assume an interface name such as `en7`. Network reachability must be measured,
not inferred from USB enumeration or a successful `net_if_up`.

The default shared bank has words 0–15 / bits 0–255. The separate profile uses
coils 0–31, discrete inputs 100–131, holding registers 200–203 and input registers
300–303. These are wire addresses. Shared-bank writes intentionally alias across
bit/register views; RTU and TCP banks remain independent.

### PC interoperability commands — only after bring-up is approved

The commands below **perform real reads/writes** to demonstration banks or run PC
servers. They are not part of software-only bootstrap. Run them only after the
programming blocker is resolved, native USB endpoints are positively identified,
and exclusive live-target access is arranged. Do not point them at production
register maps or peripherals. Replace the serial placeholder with the discovered
**native ACM** device, not the debug probe's UART.

With `server` firmware:

```sh
python tools/modbus_verify.py board-server --transport tcp \
  --profile shared --buffer-size 128 --host 192.168.77.2 --port 502 --unit 1
python tools/modbus_verify.py board-server --transport rtu \
  --profile shared --buffer-size 128 --unit 10 \
  --serial-port /dev/cu.REPLACE_WITH_NATIVE_ACM
```

With `client` firmware, run the PC TCP and RTU responders in separate terminals:

```sh
python tools/modbus_verify.py board-client --transport tcp \
  --profile shared --buffer-size 128 --unit 1 \
  --listen-host 192.168.77.1 --listen-port 1502 --duration 60
python tools/modbus_verify.py board-client --transport rtu \
  --profile shared --buffer-size 128 --unit 10 \
  --serial-port /dev/cu.REPLACE_WITH_NATIVE_ACM --duration 60
```

Match `--profile separate` and `--buffer-size 256` to the corresponding firmware
when applicable; they are separate settings, not a combined preset. The tool
supports explicit USB identity/serial/location filters, `--iterations`, `--cycles`
and optional `--json <path>` output; use `python tools/modbus_verify.py --help`
for current options. Re-identify endpoints after unplug/reset. A PC responder's
successful send does not prove the board consumed its response; independent
board logs and the validation gates remain necessary.

## 7. API, limitations and licensing

- [Migration guide](docs/migration.md): API changes, queue/completion ownership,
  cancellation boundaries, mapping and exact transport-size limits.
- [Public Zephyr API](lib/modbus/Inc/Modbus.h) and
  [portable core API](lib/modbus/Inc/ModbusCore.h): authoritative declarations.
- [Upstream derivation and modifications](lib/modbus/UPSTREAM.md), including
  original-function mappings, immutable source hashes and CRC convention.
- [LGPL-2.1 license text](lib/modbus/LICENSE): preserve upstream author and
  modification notices. Apache notices on application/Zephyr material do not
  relicense the Modbus library. Distributing linked firmware requires satisfying
  the applicable source and relinking obligations, not just shipping a binary.

Important limitations:

- `USART_HW_DMA` returns `-ENOTSUP`; there is no DMA emulation. IRQ UART is
  available in source, but physical RS-485 DE/RE control, electrical behavior and
  timing are **not verified** by native USB tests.
- The 128-byte default and optional 256-byte limit include the **RTU ADU**.
  TCP reserves four extra bytes (132/260 total), giving both transports equal
  PDU capacity. The enlarged profile supports protocol-maximum quantities;
  map and caller-word capacities can still impose smaller limits.
- The current master has one active transaction **per handler**, not per TCP
  slot. Callers retain payload/completion storage until acknowledged completion.
- CDC reconnect queue isolation is corrected by the pinned SDK patch in
  `patches/zephyr-cdc-session-isolation.patch`; `tools/build.sh` applies it.
  Actual-driver regressions pass for both workqueues (`sh tests/cdc/run.sh`).
  Physical USB enumeration, reconnect, cold boot, transport interoperability
  and stack headroom remain unverified. The latest baseline flash attempt
  erased application sectors but timed out during programming: the board's
  APROM is incomplete. Preserve the original backup and obtain an M3351-specific
  vendor recovery procedure as described in `docs/validation.md`; recovery of this
  exact state has not been demonstrated. The available host is macOS only. Do not
  blindly retry programming, mass erase or change security settings.
- The pinned M3351 Zephyr integration lacks an entropy device/driver. Demo
  `prj.conf` explicitly permits `CONFIG_TEST_RANDOM_GENERATOR=y` to satisfy TCP's
  random API dependency, as in the zperf baseline. This is a **test-only,
  non-production security configuration**. Hardware TRNG integration and network
  security hardening are outside this port. Keep it on an isolated test network;
  Modbus TCP here is neither authenticated nor encrypted.
