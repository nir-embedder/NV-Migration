# Migration from STM32/HAL/FreeRTOS to NK-M3351KI/Zephyr

This document describes the implemented source interfaces and intentional
compatibility changes, not physical-board acceptance. The library is a port of
**alejoseb/Modbus-STM32-HAL-FreeRTOS**, not a wrapper around Zephyr's Modbus
subsystem. Build, test and physical-validation evidence belongs in
`docs/validation.md`; application setup belongs in the project `README.md`.

## 1. Source identity and actual derivation

The reference library revision is
`9c022fd2538edb5b53e2e07c98ebbe9a4685546c`. Zephyr is pinned in
[west.yml](../west.yml) to `5c71a733110403a2e01f6cabd922b5f0198e9981`.
The upstream library credits Alejandro Mera and adaptation from
`smarmengol/Modbus-Master-Slave-for-Arduino`.

| Upstream source/behavior | Port location and treatment |
| --- | --- |
| `Modbus.h` FC enum and telegram fields | [ModbusCore.h](../lib/modbus/Inc/ModbusCore.h) retains the supported FC names and useful telegram names; OS/network-dependent fields are replaced, not binary-compatible. |
| `Modbus.c` `getCoilsRegion`, `getDIRegion`, `getHRRegion`, `getIRRegion` | [ModbusCore.c](../lib/modbus/Src/ModbusCore.c) retains those helper names, per-region pointer selection and zero-based shared-array fallback. |
| `process_FC1/3/5/6/15/16` | Same internal function families retain relative bank addressing, packed-coil word/bit indexing, individual bit writes, and register high/low-byte loops. FC1 also handles FC2; FC3 also handles FC4. |
| `SendQuery`, `get_FC1`, `get_FC3`, `validateRequest`, `validateAnswer` | `mb_core_build`, `mb_core_parse`, `mb_core_server` preserve encoding/decoding and dispatch while adding explicit capacities and complete validation before mutation. |
| `word`, `calcCRC`, `buildException` | Endian-independent word construction, the original reflected CRC polynomial/loop, and function-high-bit exception encoding; CRC numeric-return convention intentionally changes below. |
| Init/Start/query APIs and master/slave task organization | [Modbus.c](../lib/modbus/Src/Modbus.c) preserves handler roles, queued queries and front injection, but replaces the FreeRTOS lifecycle with static Zephyr storage, one worker per running handler, and explicit completions. |
| `sendTxBuffer`, `getRxBuffer`, UART/CDC workers | [ModbusRtu.c](../lib/modbus/Src/ModbusRtu.c) preserves RTU addressing/CRC/broadcast behavior; replaces HAL calls and USB-packet assumptions with interrupt UART I/O and bounded stream assembly. |
| TCP connection slots and `TCPwaitConnData`/`TCPinitserver` | [ModbusTcp.c](../lib/modbus/Src/ModbusTcp.c) replaces lwIP netconn objects with nonblocking IPv4 sockets and independent per-peer buffers, offsets and elapsed deadlines. |

The extraction is not a verbatim whole-file import: HAL, FreeRTOS/CMSIS-RTOS,
lwIP and STM32 example-project machinery are deliberately excluded. Detailed
upstream function/line mappings, pristine input hashes, modification notices
and core deviations are in [UPSTREAM.md](../lib/modbus/UPSTREAM.md).
`mb_rtu_frame_length` and the new stream/lifecycle mechanisms are new port code,
not claims that upstream already implemented them.

## 2. Public API and ownership changes

The application includes [Modbus.h](../lib/modbus/Inc/Modbus.h). The portable
core can be used independently through `ModbusCore.h` and has no Zephyr headers.
`ModbusInternal.h` is included to provide statically sized private storage; its
fields and `mb_*` transport helpers are **not** application interfaces.

### Handler and configuration migration

| Previous usage | Current usage |
| --- | --- |
| HAL UART handle in `port` | `const struct device *port`; choose a ready Zephyr UART or the CDC ACM UART device. TCP ignores this field. |
| Shared/separate bank fields directly in handler | Same data-model fields under `handler.memory` (`mb_memory_t`). |
| HAL `EN_Port`/`EN_Pin` direction control | Not provided. Physical RS-485 direction/timing requires separate work and validation. |
| FreeRTOS task notification via `u32CurrentTask` | Caller-owned `struct modbus_completion *completion`, or blocking `ModbusQueryV2`. |
| `void` initialization/query calls and old `ERR_*`/`OP_OK_QUERY` codes | Check `int` results: zero success, negative errno failure; completed protocol requests can return a positive Modbus exception. Old success value `OP_OK_QUERY == 20` is not retained. |
| Tick-based `u16timeOut` | Field name retained but type is `uint32_t`, units **milliseconds**; zero selects 1000 ms during Init. |
| lwIP IP/connection objects | `modbus_t.xIpAddress` is an IPv4 address in **network byte order**; query `u16Port` is host-order port number, zero selects 502. `u8clientID` selects a bounded connection slot. |
| External worker/timer/ring-buffer control or counters | Private to the implementation; do not mutate `_private`, call worker helpers, or depend on old handler layout/statistics fields. |
| Global `setTimeOut`/`getTimeOut` declarations | Not exported. Configure the handler timeout before initialization. |

Allocate handlers in static, initially zeroed storage. Configure role,
transport, unit, bank pointers and optional initialized `memory_lock` before
`ModbusInit`, and keep configuration and mappings unchanged while initialized
and running. Do not repeatedly zero or reinitialize a live handler.
`MB_MASTER` requires handler unit 0; `MB_SLAVE` requires 1–247. A server needs
at least one non-NULL bank pointer; actual accessible ranges are checked per
request. `USART_HW_DMA` is rejected with `-ENOTSUP`.

`ModbusInit` validates configuration and prepares synchronization; a second Init
returns `-EALREADY`. `ModbusStart` claims a running-handler slot, starts the
transport and worker, and returns errors instead of entering an infinite
allocation-failure loop. `ModbusStartCDC` is the USB_CDC_HW-checked Start entry
point, **not** USB descriptor/controller initialization. A UART device can belong
to only one running handler (`-EBUSY` otherwise). Start after Stop is supported.
Init/Start/Stop are thread-context operations. Handler lifetime must also cover
late device callbacks; retain static storage after Stop.

### Query lifetime, ordering and completion

- `ModbusQuery` appends; `ModbusQueryInject` prepends to the pending FIFO without
  discarding existing entries or preempting the active request. The default
  queue holds two **pending** telegrams in addition to one active transaction.
- Enqueue copies telegram metadata, **not** the payload or completion object.
  An enqueue failure transfers no ownership. Enqueue success is acceptance,
  not proof that protocol encoding or the exchange succeeded; some validation
  errors are delivered through the completion by the worker.
- Initialize each completion with `ModbusCompletionInit` before first use and
  only while it is unowned. Its semaphore/result and the payload storage must
  remain valid and must not be reused while the library owns the request.
  A completion cannot be shared by simultaneous accepted requests (`-EBUSY`).
- Ownership returns when `k_sem_take(&completion.sem, ...)` **succeeds**. Only
  then inspect `completion.result`, modify/free/reuse payload storage, or reuse
  the completion. A timed semaphore wait expiring does **not** cancel a request.
  Do not infer ownership release by polling the internal `in_flight` flag.
- `ModbusQueryV2` uses its own completion and ignores `telegram.completion`.
  It waits for actual completion/cancellation acknowledgment, so stack payloads
  are safe after return. Do not call it from an ISR or the handler's worker.
- The timeout begins when the worker takes a query, not while it waits in the
  pending queue. It includes the active transport exchange. There is no public
  per-query cancellation API or independent caller-side V2 wait deadline.
- Each handler currently has **one active request overall**, including TCP.
  Four TCP slots are endpoint/connection caches, not four simultaneously active
  queries within one master handler. Independent handlers have independent
  workers. TCP server peers are serviced with independent state/backpressure.

A minimal asynchronous read, from a thread with an already running master:

```c
static uint16_t words[4];
static struct modbus_completion done;

/* Before the first submission, while unowned. */
ModbusCompletionInit(&done);
modbus_t q = {
    .u8id = 10, .u8fct = MB_FC_READ_REGISTERS,
    .u16RegAdd = 0, .u16CoilsNo = 4,
    .u16reg = words, .u16regCapacity = 4, .completion = &done,
};
int result = ModbusQuery(master, q);
if (result == 0) {
    k_sem_take(&done.sem, K_FOREVER);
    result = done.result;
}
```

Use the selected server's actual unit and map address (200 for the separate
holding-register demo). For TCP also supply network-order `xIpAddress`, the
peer's port, and a valid client slot. `u16regCapacity` is always **uint16 words**,
not bytes or coils; coil queries need `ceil(quantity / 16)` words. FC5/6 require
`u16CoilsNo == 1`. FC5 uses zero/nonzero in `u16reg[0]` for OFF/ON, matching
upstream, while the generated wire value is strictly `0x0000`/`0xff00`.

### Stop, reset and concurrency

`ModbusStop` joins the worker, stops the transport and completes still-outstanding
accepted requests with `-ECANCELED`; it does not abort the thread while it owns
caller pointers. A request already completed retains its result. Stop from the
worker is rejected with `-EDEADLK`.

`ModbusTransportReset` is the callback/ISR-safe notification entry point. It
sets a flag and wakes the worker; cleanup is asynchronous. The worker discards
partial transport state and fails outstanding accepted work with `-ECONNRESET`.
A reset notification itself is **not** permission to free payloads: wait for
completion. New submissions are rejected while reset is pending. Deadlines are
checked against the current worker-owned request, not delivered as stale timer
callbacks carrying caller pointers.

The library allocates handler, queue, frame and peer storage statically; Zephyr's
USB/network stacks still have their own configured resources. Bank locking is
optional only when the application can otherwise guarantee exclusive access.
When handlers or application threads share a bank, supply the **same initialized
`k_mutex`** and use it for application access too. The runtime holds it only for
core bank access, not network/USB I/O, with a finite handler-timeout lock wait;
a failed lock produces exception 6 (server busy). Do not hold it while waiting
for a query or stopping handlers. UART callbacks move bounded data under
spinlocks and wake the worker; they do not parse PDUs, take a bank mutex or call
sockets.

## 3. Data model and strict protocol validation

The default demo in [demo_data.c](../src/demo_data.c) has **two independent**,
zero-initialized 16-word shared banks: RTU server unit **10**, TCP server unit
**1**, TCP port **502**. Within each bank, FC1/2/5/15 see 256 packed bits and
FC3/4/6/16 see the same 16 words. Consequently a holding-register write can
change subsequent coil/discrete-input reads in shared mode; this is intentional
upstream aliasing, not four independently protected address spaces.

With `CONFIG_APP_SEPARATE_REGIONS=y`:

| Region | Functions | First protocol address | Allocated words | Accessible addresses |
| --- | --- | ---: | ---: | --- |
| Coils | 1, 5, 15 | 0 | 2 | 0–31 bits |
| Discrete inputs | 2 | 100 | 2 | 100–131 bits |
| Holding registers | 3, 6, 16 | 200 | 4 | 200–203 words |
| Input registers | 4 | 300 | 4 | 300–303 words |

These are zero-based **wire addresses**, not human-facing `4xxxx` register
notation. Every region's count is allocated **words**, including packed-bit
regions. The separate pointer is chosen per type; a NULL pointer falls back to
`u16regs/u16regsize` at base zero, ignoring that separate region's start/count.
A non-NULL zero-sized region stays empty. Non-word-aligned bit-region bases work
because addressing is relative to the selected region. A missing shared array
cannot supply a fallback. Application code owns the arrays and their lifetimes.

`CONFIG_APP_LARGE_TEST_MAP=y` increases the shared bank to 128 words (2048 bits)
for test traffic, not the separate regions. `config/large-buffer.conf` selects
that map and a nominal 256-byte RTU ADU limit (260-byte TCP storage). It cannot be combined with separate-region
mode as a way to enlarge those regions.

The core enforces exact PDU shape, nonzero/spec-bounded quantities, complete
payloads, exact FC15/16 byte counts, FC5 wire values, and address/count bounds
before writes. Address ranges may not wrap beyond 65535. Malformed requests
return exception 3; unavailable/out-of-range banks return exception 2; unknown
functions return exception 1. Insufficient local output capacity is a negative
errno, not a promise of a wire exception. Failed requests do not partly update
a bank. Client parsing validates the expected FC, byte count, exact length and
all echoed address/value/quantity fields before changing caller data. Unused
high bits in the last returned packed-coil word are cleared, unlike upstream's
stale-bit retention.

## 4. Equal PDU capacity across transports

[ModbusConfig.h](../lib/modbus/Config/ModbusConfig.h) maps the library's limits
to [Kconfig](../lib/modbus/Kconfig). `CONFIG_MODBUS_PORT_BUFFER_SIZE` is the
**nominal RTU ADU capacity**, including its unit and CRC, and ranges from 32 to
256 bytes (default 128). The RTU ingress ring is twice that configured size.
TCP reserves **four extra bytes** for its larger header: 132 bytes by default,
260 bytes at setting 256. Both transports therefore have `B - 3` PDU bytes.
Account for both request and response, not just the smaller read request:

| Operation | Protocol quantity maximum | B=128, either transport | B=256, either transport |
| --- | ---: | ---: | ---: |
| FC1/2 read bits | 2000 | 984 | 2000 |
| FC3/4 read words | 125 | 61 | 125 |
| FC15 write bits | 1968 | 952 | 1968 |
| FC16 write words | 123 | 59 | 123 |

These are **frame-size ceilings**, not demo-bank capacities. The map, remaining
address range and query buffer can impose smaller limits. FC5/6 always operate
on one item. The formulas are `2 + ceil(N/8)` / `2 + 2*N` for read response PDUs,
and `6 + ceil(N/8)` / `6 + 2*N` for multiple-write request PDUs, capped by the
protocol maxima. A maximum 125-register TCP read response is 259 bytes and fits
the enlarged profile; it is not truncated to 256 bytes. This overhead allowance
preserves the configured RTU capacity without silently reducing TCP quantities.

A request can fit while its expected response cannot. An oversized read is not
automatically divided into smaller operations: choose a supported count in the
client. Depending on which boundary detects it, an exchange may fail locally,
close a TCP peer, or time out rather than returning a Modbus exception.

Other explicit defaults are two pending queries, four TCP connections, four
concurrently started handlers, a 3072-byte stack per handler and priority 5.
The handler-count default is intentionally four rather than the upstream
configuration template's two. Each setting has a bounded Kconfig range; more
buffers/stacks/peers consume RAM and do not establish measured stack headroom.

## 5. Transport changes

### RTU over native CDC ACM and physical UART

A USB transfer or UART FIFO callback is not an ADU boundary. The adapter retains
bounded incoming bytes and partial output offsets. For CDC it uses supported
FC shapes and byte counts to infer complete candidates, verifies CRC, and
retains subsequent bytes. Incomplete/unknown/malformed streams have a
configurable idle assembly expiry, `CONFIG_MODBUS_PORT_CDC_ASSEMBLY_MS` (100 ms
default). Overflow is explicit; it is not silent overwrite or unbounded growth.
An overflow fails an active query with `-ENOBUFS`; transaction/transfer deadline
expiry uses `-ETIMEDOUT`.

`calcCRC(data, length)` now returns the conventional numeric CRC16/Modbus:
`"123456789" -> 0x4b37`. Transmit its **low byte first**, then high byte. Upstream
returned a swapped integer; copying its old append code without adapting this
contract would reverse the CRC. Wire behavior remains unchanged.

The transport rejects bad CRC without a response. Servers filter unit IDs and
accept only write functions for RTU unit-zero broadcast; broadcasts never get a
reply. A master's accepted write-broadcast completes without waiting for a
server response, which does not prove that any server applied it. Read broadcasts
are rejected. RTU replies must match the active unit before the core checks FC,
length, count and echo; wrong-unit/CRC traffic is ignored.

CDC line coding is not physical UART timing and startup does not wait for DTR.
The physical `USART_HW` adapter instead reads its Zephyr UART configuration:
8 data bits, one/two stop bits, none/even/odd parity and no flow control. It derives
T1.5/T3.5 from the character format at up to 19200 baud and uses 750/1750 us above
19200. FIFO acceptance is not wire completion; the implementation reserves a
conservative whole-frame airtime plus T3.5 after FIFO acceptance. FIFO timestamp
resolution and real-wire timing still need measurement.

**DMA is not implemented:** selecting `USART_HW_DMA` returns `-ENOTSUP`; there
is no silent IRQ fallback. **Physical RS-485 is not accepted or certified:** no
DE/RE GPIO control, transceiver turnaround or electrical-bus verification is
supplied. USB RTU tests cannot establish any of those properties.

### TCP over native CDC ECM

The port uses Zephyr IPv4 sockets, not a second lwIP stack. Each bounded peer
slot has its own receive accumulator, transmit offset, connection endpoint and
last-activity timestamp. It handles fragmented/coalesced MBAP ADUs and partial
sends without assuming one `recv` is one request. Pending replies apply
per-peer backpressure. A full server pool closes additional accepted sockets;
it does not overwrite another peer's state.

MBAP requires **both** protocol-ID bytes to be zero (correcting upstream's OR
test), a valid body length including unit, and total size within the configured
buffer. TCP carries no RTU CRC. Master replies must match slot, transaction ID
and unit before core PDU validation; a mismatch closes the connection with an
error. Reusing a client slot for a different IP or port closes/reconnects instead
of sending to its former endpoint. Close/error/timeout paths release peer state.

Server listen port zero selects 502. The listener currently binds IPv4
`INADDR_ANY`; the demo supplies ECM networking, but this is not an interface-
restricted or authenticated service if more interfaces are later enabled.
TCP unit-zero broadcast is not supported. The default idle timeout is explicitly
**40000 ms**, replacing round-robin poll aging. It reflects the reference budget
of four slots × 1000 aging visits × a suggested 10 ms server poll interval,
not a claim that all FreeRTOS tick configurations had that duration. Changing
transaction timeout does not implicitly change `tcp_idle_ms`.

## 6. Board, native USB and application boundary

The selected build target is `numaker_m3351ki/m335xxx`. The user confirmed the
physical MCU is **M3351KJCAE**. The pinned upstream DTS includes `m3351kjc.dtsi`,
whose **1 MiB KJ** flash map is retained. The project
[board overlay](../boards/numaker_m3351ki.overlay) removes the unused MCUboot
partitions and deletes `zephyr,code-partition`; [prj.conf](../prj.conf) disables
DT code-partition use. The intended image is a direct APROM application at
**offset 0**, not an MCUboot slot image, with 128 KiB SRAM. `pyocd.yaml` selects
`m3351kjcae`; Nuvoton DFP 1.0.6 maps it to `M3351_AP_1M.FLM`.

The earlier 512 KiB KI override and programmer selection were incorrect for this
chip and have been removed. Historical logs are retained unchanged. The original
512 KiB backup covers only the lower half of KJ APROM, not the full device.
The mismatch is not yet proven to explain the previous programming failure;
correct selection is not proof of safe recovery or authorization to change
security configuration. Check the final merged DTS, linker map and device
support separately.

The application uses the target's native USB connection for one full-speed
**CDC ACM + CDC ECM composite** configuration: ACM carries binary RTU and ECM
carries ordinary TCP/IP. It does not use the debug probe's UART as the Modbus
transport or tunnel TCP through serial. Diagnostics remain on upstream UART0,
not the binary ACM channel.

[usb.c](../src/usb.c) owns USB lifecycle through public `usbd_*` APIs, adapting
Zephyr's USB initialization example while preserving its notice. It registers
`cdc_acm_0` and `cdc_ecm_0`; competing CDC boot initialization is disabled.
USB reset/VBUS removal signals transport resets for RTU and TCP. VBUS-dependent
enable/disable follows controller support. CDC session boundaries signal RTU reset
only; DTR never gates TCP or startup.

### CDC reconnect isolation for the pinned SDK

Upstream at `5c71a733110403a2e01f6cabd922b5f0198e9981` retains
`tx_fifo.current` and RX FIFO contents across class disable and DTR close. The
project's [CDC patch](../patches/zephyr-cdc-session-isolation.patch) corrects that
existing driver; it is not a replacement USB stack or class. `tools/build.sh`
applies it idempotently through [patches/apply.sh](../patches/apply.sh), refusing
a different revision or conflicting edits. Direct `west build` users must run
`sh patches/apply.sh` first; ignored `.deps` edits alone are not the deliverable.

A class disable (including the stack's bus-reset path) or explicit DTR clear
closes admission immediately. Cleanup on the same CDC workqueue drains RX,
resets retained TX/ZLP/echo state, and dequeues bulk IN/OUT and notification IN
outside spinlocks. Enqueue already executing must finish before this worker;
notification submitters outside the queue hold a counted submission fence.
The class waits **without blocking or timer polling** for all counted USB-owned
buffers to return. Late successes and cancellations cannot seed the next RX
FIFO or TX session. Dequeue failure with outstanding ownership leaves CDC closed;
a subsequent boundary can retry. Buffer ownership is never forcibly reclaimed.

The optional `usbd_cdc_acm_set_session_cb()` extension runs outside driver locks
on that queue after local purge, before reopening. `src/usb.c` uses it to request
RTU protocol reset; the old asynchronously delivered line-state query is removed
because a rapid low/high could make both messages report high. Register before
USB enable; callbacks must not wait on work on the same queue. Multiple closes
may coalesce. First enumeration also invokes it and permits binary operation
without waiting for DTR. An explicit DTR clear remains closed until DTR is raised
or a fresh configuration is enabled. Notification sends reject IRQ/workqueue
contexts, serialize completion ownership, and retain cancellation wakeups even
when completion precedes the sender's wait. UART FIFO fill only schedules the
potentially sleeping UDC enqueue, including when called under a protocol lock.
The existing SDK echo-mitigation delay is unchanged; no reconnect delay is added.

[Dedicated driver regression tests](../tests/cdc/README.md) compile the real
patched class against mocked USB/UDC endpoints and real Zephyr kernel primitives.
Recorded QEMU result: **20/20 passed on each of system and dedicated workqueues**,
including delayed/in-progress payload completion races, partially consumed RX,
exact 128/256-byte FIFO streams and 40 reconnect cycles per run.
The target application also builds with the patch. These checks do not establish
physical enumeration, Nuvoton UDC cancellation behavior or simultaneous on-board
RTU/TCP recovery; those remain live-hardware acceptance checks.

`CONFIG_APP_USB_VID` and `CONFIG_APP_USB_PID` both default to **zero**. This permits
compile checks, but `app_usb_init` returns `-EINVAL` if either remains zero; main
stops the handlers and reports startup failure. For this isolated bench demo the
user explicitly requested an existing development configuration after investigation.
The ignored local `config/usb-identity.conf` selects **0416:B002**, from Nuvoton's
M3351 BSP V3.00.002 `USBD_VCOM_SerialEmulator` example. This is not a manufacturer
grant, project allocation, or production identity; do not ship it in a product.
The original APROM contains HID identity 0416:B001, which is not reused. The
Zephyr sample-only 2fe3:0001 identity is also not reused. See the README for
provenance and restrictions. Build configuration is not USB enumeration evidence.

[network.c](../src/network.c) configures the ECM interface with a static /24 IPv4
address and no gateway. Defaults are board `192.168.77.2`, peer `192.168.77.1`;
the client demo's configurable peer TCP port defaults to 1502. The overlay uses
locally administered MAC addresses `02:4e:56:33:51:02` (device) and
`02:4e:56:33:51:01` (host side). These example identities must be unique when
multiple boards are used; host addressing and subnet-conflict checks remain
separate setup steps. Firmware initialization does not configure the Mac or
prove network reachability.

### Demo-only random generator: not production security

The pinned M3351 devicetree/driver integration has no enabled entropy device or
M3351 entropy driver, while Zephyr's TCP implementation requires `sys_rand_get`.
The application therefore explicitly sets `CONFIG_TEST_RANDOM_GENERATOR=y` in
its demo `prj.conf`, using the same application-level opt-in as the pinned
`samples/net/zperf/prj.conf`. This is **not** a library requirement or a change
to the board configuration, and it does not mean the physical MCU lacks a TRNG.

Zephyr's `subsys/random/Kconfig` describes this option as allowing non-random
results for tests, selects `NOT_SECURE`, and explicitly forbids treating it as
production configuration. With no entropy-backed generator available, its
fallback is the system-timer-based test generator. Successful TCP operation
with this setting is not evidence of adequate entropy, unpredictable network
behavior, or cryptographic security. Keep this demo on an isolated test network;
it is **not suitable for production or network-security use**.

Hardware TRNG/entropy-driver integration, validation of the selected random
source and production network-security hardening are outside the current port.
Do not carry the test-generator opt-in into a production configuration or
infer secure-production readiness from passing protocol/build tests.

## 7. Licensing and verification boundary

The upstream-derived library retains the upstream
[LGPL version 2.1 license text](../lib/modbus/LICENSE), author/adaptation credits
and modification provenance. Apache-2.0 notices on first-party application and
Zephyr-derived USB/example material do not relicense the linked Modbus library.
Preserve the notices of every included component.

For redistribution, provide the applicable modified library source and notices
and satisfy LGPL section 6 for the linked work, including an applicable way to
relink with a modified library (for example, application object files and the
necessary build/link materials). A binary, this guide or the source hash list
alone is not a complete compliance package; consult the license itself.

Library SPDX markers use **LGPL-2.1-only**, aligned with the conservative
upstream grant recorded in `UPSTREAM.md`; no additional "or later" grant is
assumed. Preserve the original license text and function-level provenance.

The [portable test suite](../tests/protocol/README.md) exercises the extracted
core without a board. Runtime/transport test sources live in `tests/zephyr`;
source presence alone is not a passing result. Neither host tests, emulated
checks, compilation nor source review proves physical USB enumeration,
interoperability, reconnect behavior, flash support, stack headroom or RS-485
timing. This migration guide makes **no physical-acceptance claim**.
