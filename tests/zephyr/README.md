# Zephyr Modbus port integration tests

These are real `ztest` tests running Zephyr on `qemu_cortex_m3`, not host mocks
of the kernel. The UART test device implements the pinned interrupt UART API
and deliberately accepts at most three bytes per FIFO fill. TCP tests use
Zephyr's actual IPv4 loopback/socket stack. No physical probe, UART, USB device,
network interface configuration, installation, or flash operation is performed.

## Reproduce

From the project root, with the parent-provided dependencies already installed:

```sh
export ZEPHYR_BASE="$PWD/.deps/zephyr"
export ZEPHYR_SDK_INSTALL_DIR="$PWD/.toolchains/zephyr-sdk-1.0.1"
export PATH="$PWD/.venv/bin:$PATH"

west build -b qemu_cortex_m3 -d tests/zephyr/build-rtu tests/zephyr
python tests/zephyr/run_qemu.py tests/zephyr/build-rtu/zephyr/zephyr.elf

west build -b qemu_cortex_m3 -d tests/zephyr/build-large tests/zephyr -- \
  -DCONFIG_MODBUS_PORT_BUFFER_SIZE=256
python tests/zephyr/run_qemu.py tests/zephyr/build-large/zephyr/zephyr.elf

west build -b qemu_cortex_m3 -d tests/zephyr/build-tcp tests/zephyr -- \
  -DEXTRA_CONF_FILE=tcp.conf
python tests/zephyr/run_qemu.py tests/zephyr/build-tcp/zephyr/zephyr.elf

west build -b qemu_cortex_m3 -d tests/zephyr/build-tcp-large tests/zephyr -- \
  -DEXTRA_CONF_FILE=tcp.conf -DCONFIG_MODBUS_PORT_BUFFER_SIZE=256
python tests/zephyr/run_qemu.py tests/zephyr/build-tcp-large/zephyr/zephyr.elf
```

`run_qemu.py` launches only the named emulator, recognizes ztest's execution
verdict, terminates its own emulator process, and returns nonzero on failure,
fatal error, missing verdict or timeout. This is useful on macOS where an
ordinary `west build -t run` does not exit on the final ztest banner. Its default
30-second bound covers the intentional TCP TIME_WAIT isolation between cases.

`testcase.yaml` also supports standard Twister discovery. The initial Twister
attempt was blocked by missing `junitparser` in the supplied virtual environment;
the standalone runner needs only Python's standard library and QEMU.

## Recorded software validation (2026-10-28)

Using the pinned local Zephyr checkout, SDK 1.0.1 and the host QEMU:

| Configuration | ztest result | Firmware flash / RAM |
| --- | --- | --- |
| RTU, 128-byte nominal capacity | 13 passed, 0 failed | 40,864 / 14,384 bytes |
| RTU, 256-byte nominal capacity | 13 passed, 0 failed | 40,872 / 16,688 bytes |
| RTU + TCP loopback, 128-byte nominal capacity | 19 passed, 0 failed | 100,264 / 44,336 bytes |
| RTU + TCP loopback, 256-byte nominal capacity | 19 passed, 0 failed | 100,268 / 48,432 bytes |

Local machine-generated evidence is `build-rtu/run.log`, `build-large/run.log`,
`build-tcp/run.log`, `build-tcp-large/run.log`, and captured `build.log` files.
These are ignored build artifacts, not checked-in fabricated transcripts.
`python -m py_compile tests/zephyr/run_qemu.py` also succeeded. These footprint
numbers describe the QEMU **test images**, not the production M3351 image.

All four final images were compiled with SDK 1.0.1 ARM GCC and executed using
`/opt/homebrew/bin/qemu-system-arm`: 64 cases passed, with no failures or skips.
A separate pristine TCP-enabled build (`build-clean-deps`) passed all 19 cases.
Its `build.log` records `heap_constants.h` generation at step 10, before
`ModbusTcp.c` at step 22, `ModbusRtu.c` at step 23, and `Modbus.c` at step 24.
The library explicitly depends on `zephyr_generated_headers` in
`lib/modbus/CMakeLists.txt`; linking only `zephyr_interface` does not provide
this build-order guarantee.

The final default RTU image also passed 20 consecutive complete repeat runs:
260 cases, no failures or skips. Logs are `build-rtu/repeat-01.log` through
`repeat-20.log`.

### Expiry-test investigation

The old test assumed that sleeping for `CDC_ASSEMBLY_MS + 5` meant the worker
had expired a partial frame, and that a further 2-ms sleep meant TX state was
idle. A kernel sleep is not an acknowledgement of either worker transition.
The revised test uses bounded 500-ms state waits: observe the queued prefix
assembled, observe its actual idle expiry, verify no response or bank mutation,
then complete a valid request and observe TX idle before starting an unknown
function. The unknown-function exception must still have the correct code and
CRC. The response timeout is not extended and runtime expiry is not disabled.
State snapshots exclude the worker with the scheduler lock on the test's
uniprocessor target and exclude UART callbacks with the existing I/O spinlock.

An additional test prevents the worker from consuming either ingress batch
until both are queued. Controlled arrival timestamps verify both sides of the
boundary: a continuation one microsecond before expiry retains the prefix; a
complete request exactly at expiry discards the stale prefix and succeeds.
This exercises the arrival-gap path independently of emulator sleep timing.
The runtime already handles both cases; no expiry algorithm change was needed.
The historical intermittent failure was not reproduced as a runtime defect,
so these results do not claim a conclusively identified historical root cause.

## Coverage

RTU-only configurations exercise 13 cases:

- Init validation, unsupported DMA, idempotent stop, restart, and no-DTR startup.
- Every split point of a supported RTU frame, coalesced frames, invalid CRC,
  write broadcast/no response, and a 73-byte request split at USB byte 64.
- Configured response-capacity boundary (127-byte ADU at default size and
  255-byte ADU at size 256); FIFO partial acceptance preserves every byte.
- Observed incomplete-frame expiry, unsupported-function CRC/expiry response,
  and just-before/at-expiry arrivals while the worker is deliberately delayed.
- FIFO query ordering, prepend without dropping work, metadata copying,
  queue-full and completion-in-use errors.
- Actual ISR reset notification via `irq_offload`, cancellation of active and
  pending requests, stop acknowledgement and ownership release.
- Blocking timeout under zero-byte TX acceptance, bounded RX overflow,
  wrong-unit/corrupt-CRC filtering, exception and malformed-reply completion.
- 9600-8E1 timing calculation and a controlled 2500-us ingress gap between
  calculated T1.5 and T3.5. This is algorithm verification, not measured UART
  electrical timing.

TCP-enabled configurations add six cases (19 total):

- A real library master/server pair performs a 77-byte FC16 request and a
  capacity-boundary FC3 read: 61 registers at nominal size 128 or 125 at 256,
  producing a 131-byte or 259-byte TCP ADU respectively. The 125-register test
  validates every returned word against the server bank through real sockets.
- Exact MBAP length/PID checks, acceptance at the configured TCP capacity,
  rejection beyond that capacity, and the absolute 260-byte protocol limit.
- All header/request split points, coalesced ADUs, four simultaneous clients.
- Master response matching, fragmented response, exception result, endpoint
  replacement in one slot, wrong transaction/unit rejection, disconnect,
  timeout and unchanged caller buffer on failure.
- Full-pool rejection, elapsed idle expiry, both nonzero PID-byte cases and
  subsequent connections. Tests preserve Zephyr's TIME_WAIT protection.
- Two independently started RTU/TCP workers with one shared bank mutex.

TCP uses nonblocking partial-send offsets in production code; these tests do
not force every possible kernel partial-send/EAGAIN interleaving. Target USB
reset/unplug, endpoint buffering, RS-485 electrical/direction timing and physical
UART FIFO timestamp accuracy remain hardware acceptance work. The test-only
random generator in `tcp.conf` must not be copied into production security
configuration.

## Library integration and intentional limits

Application CMake uses `add_subdirectory(lib/modbus)` after Zephyr initialization;
application Kconfig sources `lib/modbus/Kconfig`. All new options start with
`MODBUS_PORT_`; this library does not enable or link Zephyr Modbus. APIs and
caller-buffer/completion ownership are documented in `lib/modbus/Inc/Modbus.h`.
Initialize handlers from static zeroed storage, check all integer API results,
and configure a shared `memory_lock` when banks overlap. A bank lock is held
only during core access, never during socket/UART I/O.

`CONFIG_MODBUS_PORT_BUFFER_SIZE` is the **nominal RTU ADU capacity**, including
unit and CRC: 128 bytes by default or an optional 256 bytes. Both transports
reserve the same PDU capacity (`setting - 3`): 125 or 253 bytes. TCP replaces
RTU's three transport bytes with seven MBAP/unit bytes, allocating four extra
bytes per buffer: **132 bytes** by default or **260 bytes** at setting 256.
The large profile supports a 125-register response: 255 RTU bytes or 259 TCP
bytes. The tests use a 128-word bank to exercise these boundaries.

The TCP client is serial per handler, retaining upstream's one master worker;
four slots cache endpoints, while servers concurrently service four clients.
Ports default to 502; idle expiry defaults to 40000 ms, derived from the chosen
reference's four connections, 1000 aging passes and 10-ms receive wait. The
request deadline defaults to 1000 ms and starts when a queued request becomes
active. Accepted async buffers remain caller-owned but inaccessible for reuse
until the completion semaphore is taken. `ModbusQueryV2` waits for the worker's
actual completion, including timeout/stop/reset, rather than releasing pointers
on an independent caller-side timer.

The UART adapter supports IRQ-driven 8-bit UART with none/even/odd parity,
one/two stop bits, and no hardware flow control. T1.5/T3.5 are derived from
`uart_config_get`, with 750/1750 us above 19200 baud. Conservative UART TX drain
reservation precedes another transaction. There is no RS-485 DE/RE control;
`USART_HW_DMA` is rejected with `-ENOTSUP`.

USB ownership remains with the application. Call `ModbusTransportReset` on bus
reset, unplug, or DTR close; it only notifies, while the worker clears its own
RX/TX/frame state and completes outstanding requests. The pinned CDC UART API
has **no public RX/TX purge or abort primitive**: bytes already accepted into
the CDC driver's/USB controller's queues cannot be retracted by this library.
The application USB lifecycle and physical unplug/reconnect tests must establish
that stale driver-owned bytes do not cross sessions. The library suppresses
further FIFO acceptance while reset notification is pending, but does not claim
to flush opaque driver buffers. RTU has no transaction identifier, so arbitrarily
late same-unit/same-shape replies cannot be distinguished on wire from a later
transaction; TCP correlation does not have this limitation.

## Provenance

Lifecycle/query semantics are derived from `MODBUS-LIB/Src/Modbus.c:313–566` and
`950–1003`, and the public handler from `MODBUS-LIB/Inc/Modbus.h`, at upstream
`9c022fd2538edb5b53e2e07c98ebbe9a4685546c`. RTU uses the original transport/core
separation and CRC/address roles. TCP preserves connection slots, server port,
endpoint selection and aging intent from `TCPwaitConnData`, `TCPinitserver` and
master transport code, replacing netbuf message assumptions and the incorrect
PID OR check with bounded stream parsing. Front injection intentionally does
not silently discard the old queue. STM32/FreeRTOS/lwIP types, allocation,
global protocol state and infinite error loops are removed. Runtime headers,
sources, configuration and build integration carry modification notices dated
2026-10-28 for NV-Migration and LGPL-2.1-only SPDX identifiers, without assuming
an upstream "or later" grant. `lib/modbus/LICENSE` and `UPSTREAM.md` cover the
portable core's source provenance and distribution obligations.

Zephyr APIs were checked locally at
`5c71a733110403a2e01f6cabd922b5f0198e9981`, including `drivers/uart.h`,
`drivers/uart/uart_internal.h`, `net/socket.h`, `net/net_ip.h`, the CDC sample,
and `subsys/usb/device_next/class/usbd_cdc_acm.c`. The port uses the installed
`net_sockaddr*`, `NET_*`, `ZSOCK_*` and `ZVFS_*` names rather than assuming old
POSIX aliases exist.
