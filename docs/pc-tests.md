# PC Modbus interoperability tests

`tools/modbus_verify.py` tests the **demonstration memory maps only**, with no GPIO,
actuator, or peripheral mapping. It intentionally writes the entire writable map.
Do not point it at an unrelated Modbus device. It does not flash firmware, install
packages, assign USB identities, configure host networking, change routes, or use
root privileges. All addresses below are zero-based Modbus protocol addresses,
not 1-based or 4xxxx display notation.

## Dependencies and verified API

The existing project `.venv` was inspected before implementation: Python 3.12.16,
PyModbus 3.16.1, pyserial 3.5, pytest 9.2.0. `requirements-test.txt` records those
package versions; no installation is part of running this harness. Other PyModbus
and pyserial versions are rejected rather than silently using an unverified API.

The harness uses the installed PyModbus APIs, not obsolete `slave=` examples:

- `ModbusTcpClient` / `ModbusSerialClient`, `device_id=`, keyword-only `count=`,
  and `retries=0` for positive PC-master interoperability.
- `ModbusTcpServer` / `ModbusSerialServer`, async `serve_forever(background=True)`
  and `shutdown()`, and `trace_pdu(sending, pdu)` for PC-server interoperability.
- Public `SimData` / `SimDevice` maps; shared registers use
  `use_bit_addressing=True`. There is no address-plus-one compatibility shim.
- The server's public `custom_pdu` extension retains FC5's original wire value:
  the stock decoder converts any nonzero value to `True`, which would otherwise
  hide an invalid `0x0001` ON encoding from the observer.
- Separate raw socket/pyserial checks cover malformed frames, CRC, silence,
  broadcasts, stream fragmentation and connection limits. All serial writes are
  binary `bytes`; **no LF or other delimiter is appended**.

References: [versioned client documentation](https://pymodbus.readthedocs.io/en/v3.16.0/source/client.html),
[server documentation](https://pymodbus.readthedocs.io/en/v3.16.0/source/server.html),
and installed package `server/base.py`, `server/server.py`, `simulator/simdevice.py`,
`simulator/simdata.py`, `pdu/bit_message.py`. The installed 3.16.1 signatures/source,
not older tutorials, determine the calls used here. The PyModbus web simulator UI
is not used.

## Required selections and endpoints

Every invocation requires a role, `--transport rtu|tcp`,
`--profile shared|separate|large`, and `--buffer-size 128|256`. Select the actual firmware
configuration; the harness does not infer it from responses or enlarge the map
when a larger buffer is selected.

`--buffer-size` is the **nominal RTU ADU size**, including unit and CRC, matching
`CONFIG_MODBUS_PORT_BUFFER_SIZE` in `lib/modbus/Kconfig`. As defined in
`lib/modbus/Config/ModbusConfig.h`, TCP gets four additional bytes for its larger
transport header. Both transports therefore have the same PDU capacity:

| CLI / configuration value | RTU ADU capacity | TCP ADU capacity | PDU capacity | Maximum MBAP Length |
| ---: | ---: | ---: | ---: | ---: |
| 128 | 128 | 132 | 125 | 126 |
| 256 | 256 | 260 | 253 | 254 |

The MBAP Length field counts the unit identifier plus PDU; it excludes the first
six header bytes. Do not pass 132 or 260 to `--buffer-size` for TCP: the CLI keeps
the nominal firmware values **128 or 256** for either transport.

| Selection | Default / meaning |
| --- | --- |
| `board-server` | PC master verifies the board's server |
| `board-client` | PC server observes and answers the board's demo master |
| RTU unit | 10; override `--unit` |
| TCP unit | 1; override `--unit` |
| `--host`, `--port` | Board TCP server `192.168.77.2:502` |
| `--listen-host`, `--listen-port` | PC TCP listener `192.168.77.1:1502`; port must be >=1024 |
| `--timeout` | 1.5 seconds per blocking response/silence operation |
| `--fragment-timeout` | 0.03 seconds to check no response to incomplete TCP input |
| `--duration` | 60-second maximum PC-server observation window |
| `--iterations` | 1 positive-suite repetition in board-server mode |
| `--cycles` | 1 verified response per FC in board-client mode |
| RTU coding | 115200, 8N1; `--baudrate`, `--parity`, `--stopbits` configurable |

CDC line coding does **not** prove physical UART timing. Read deadlines, socket
receive timeouts and asyncio events bound waits; the harness has no sleep polling.

The host must **already** have a suitable address on the isolated
`192.168.77.0/24` ECM network, with no default route added. Configuration and route
conflict checks are outside this harness. Overrides support an approved alternate
peer/subnet. The PC server binds only the specified address; there is no fallback
to all interfaces or privileged port 502.

RTU requires either an explicitly supplied `--serial-port` for the native target
CDC ACM interface, or identity selection using `--vid` **and** `--pid`,
`--usb-serial`, and/or `--usb-location`. VID/PID arguments accept `0x` hexadecimal.
Identity discovery requires exactly one match; zero or multiple matches fail.
Explicit paths and identity selectors cannot be mixed. No `/dev/cu.*` path or
VID/PID is hard-coded. For an approved sample-development build, use the exact
documented identity selected for that firmware and confirm actual enumeration;
the harness does not select an identity. Sample development IDs are not a
production allocation. Distinguish the target native CDC interface from Nu-Link
debug/UART interfaces and rediscover it after re-enumeration.

## Exact maps and packet limits

| Profile | Coils (FC1/5/15) | DI (FC2) | HR (FC3/6/16) | IR (FC4) |
| --- | --- | --- | --- | --- |
| `shared` (default application map) | 0..255, bit aliases | 0..255, same bit aliases | 0..15 | 0..15, same 16 words |
| `separate` | 0..31 | 100..131 | 200..203 | 300..303 |
| `large` (opt-in test map) | 0..2047, bit aliases | 0..2047, same bit aliases | 0..127 | 0..127, same 128 words |

Shared bit address `n` means bit `n % 16` (LSB first) of word `n // 16`.
Separate regions are independent and initialized to zero. The positive suite
first zeros writable regions, expects the separate read-only regions to be zero,
and checks all four read views after each write. This is **not** evidence of
zeroed power-on memory: the harness deliberately initializes writable memory.
RTU and TCP board banks are independent; cross-transport aliasing is not assumed.

`config/large-buffer.conf` explicitly enables **both**
`CONFIG_MODBUS_PORT_BUFFER_SIZE=256` and `CONFIG_APP_LARGE_TEST_MAP=y`. Select
`--profile large --buffer-size 256` for that image. This is a **test-only extension
of the externally visible shared map**, not a change to the default 16-word map
or the separate four-word register regions. If separate regions are enabled,
the actual map remains `separate`, even if the large-test option is also set.
A larger buffer alone does not imply a larger map. Buffer and map selections
remain independent in the CLI; a custom 128-byte large-map image must be selected
explicitly with matching arguments.

These are exact **default shared-map** sizes:

| Operation | RTU ADU | TCP ADU |
| --- | ---: | ---: |
| FC15 write 128 coils | 25 bytes | 29 bytes |
| FC15 write all 256 coils | 41 bytes | 45 bytes |
| FC16 write all 16 registers | 41 bytes | 45 bytes |
| FC1 read all 256 coils, response | 37 bytes | 41 bytes |
| FC3 read all 16 registers, response | 37 bytes | 41 bytes |

**Writing 128 coils is not a >64-byte packet test.** It runs for `shared` and
`large`; `separate` skips it because it has only 32 coils. The default `shared`
and `separate` maps still cannot produce a valid single ADU exceeding 64 bytes,
so that case stays explicitly skipped for those profiles.

### Valid large-map ADUs and exact boundaries

For `large`, `valid_single_adu_over_64_bytes` writes **32 registers** with FC16 in
one ADU: **73 bytes RTU / 77 bytes TCP**, then verifies all four aliased read views.
Additional `large_fc{function}_capacity_boundary` cases write with FC15/16 and
read with FC1/2/3/4 at the largest quantity allowed by both protocol and configured
ADU capacity. Those requests end at the last mapped bit/register. Initializing,
restoring and snapshotting the full 128-word/2,048-bit map uses multiple bounded
transactions, never an illegal 128-register or 2,048-coil single request.

With the provided **nominal 256-byte configuration**, RTU has 256 ADU bytes and
TCP has 260 ADU bytes. Both have **253 PDU bytes**, allowing the full protocol
quantity limits on either transport:

| Operation | RTU quantity / largest ADU | TCP quantity / largest ADU |
| --- | --- | --- |
| FC16 write registers | 123 / 255-byte request | 123 / 259-byte request |
| FC15 write coils | 1,968 / 255-byte request | 1,968 / 259-byte request |
| FC3/4 read registers | 125 / 255-byte response | 125 / 259-byte response |
| FC1/2 read bits | 2,000 / 255-byte response | 2,000 / 259-byte response |

These quantities are capped by the [Modbus application specification](https://www.modbus.org/specifications),
not only by available bytes. For example, 2,001 read bits or 1,969 written coils
would still fit the nominal-256 buffers but violate protocol quantity limits.
They must not be sent as valid positive tests.

With **nominal 128**, the opt-in large map has smaller, equal quantity limits on
both transports (default `shared` and `separate` maps are smaller still):

| Operation | Quantity | RTU largest ADU | TCP largest ADU |
| --- | ---: | ---: | ---: |
| FC16 write registers | 59 | 127-byte request | 131-byte request |
| FC15 write coils | 952 | 128-byte request | 132-byte request |
| FC3/4 read registers | 61 | 127-byte response | 131-byte response |
| FC1/2 read bits | 984 | 128-byte response | 132-byte response |

Every reported request/response size includes the selected transport's complete
ADU overhead. A valid large TCP ADU can exceed the nominal CLI value by four bytes.

These cases verify valid byte streams, not actual physical USB packetization.
The board-client demo still emits quantity 4 (or 1 for singles); selecting the
large PC-server map does not alter that firmware loop or claim large-client ADUs.

Independent malformed/stream >64-byte cases remain explicitly labeled:

- malformed FC16 with quantity 1, byte count 66 and 66 payload bytes: **75-byte
  RTU / 79-byte TCP ADU**, rejected without changing any read view;
- malformed FC16 ADUs exactly the selected transport's capacity and one byte
  above, likewise non-mutating: **128/129 or 256/257 RTU bytes**, and
  **132/133 or 260/261 TCP bytes**, for nominal 128/256 respectively;
- six valid, coalesced 12-byte TCP FC3 requests: **72-byte aggregate stream**, not
  a single large valid ADU and not proof of a physical USB packet boundary.

## Automated cases

### Board server / PC master

1. Actual PyModbus positive FC1, 2, 3, 4, 5, 6, 15, 16 exchanges. Check write echoes,
   every read view, bit padding, aliasing/isolation, first/last addresses, and
   the full mapped contents in protocol/capacity-bounded chunks. Deterministic
   changing patterns repeat with `--iterations`; large-map single-ADU/boundary
   cases run once per invocation.
2. Out-of-range FC1/2/3/4/5/6/15/16: exception 2; zero read quantities and invalid
   FC5 value: exception 3; unsupported FC `0x45`: exception 1.
3. Malformed FC15/16 byte counts and large/buffer-boundary frames: exception 3 or
   silent/closed rejection is accepted; success replies, partial replies, bad
   framing and any mutation are failures. Snapshot all four views before/after.
4. RTU corrupt CRC and wrong-unit writes: absolutely no reply and no mutation.
   Unit-zero FC6 and FC5 broadcasts: absolutely no reply, then addressed readback.
5. TCP 12-byte FC3 requests split at **each of the 11 byte boundaries**. No response
   or connection close may occur before the remainder arrives. Test two and six
   coalesced requests and match every transaction ID, unit and response.
6. TCP protocol IDs 1 and 256 rejected independently; MBAP lengths 0, 1 and
   nominal-buffer-size minus 1 rejected. That last value is **127 or 255**: an
   advertised ADU of **133 or 261 bytes**, exactly one byte above TCP capacity.
   A fresh valid connection must work afterward.
7. Four TCP sockets submit requests before replies are collected. A fifth must
   be closed/refused/reset or remain silent within timeout; the original four
   must still work. Closing them must permit a replacement client. The expected
   application pool is exactly four; an application built with a different pool
   size is outside this acceptance case.

The positive phase restores writable zeros. RTU broadcasts subsequently write
`0xBEEF`, then toggle coil zero so ignoring FC5 cannot pass accidentally through
shared aliasing. Final shared word zero is `0xBEEE`; separate holding register 200
is `0xBEEF` and coil zero is ON. A rerun starts by reinitializing writable state.
Failures can leave other test patterns behind.
There is no concurrent RTU master: do not run a terminal or another PC master on
that CDC interface while testing.

### Board client / PC server

The PC server counts decoded requests and verifies outgoing PyModbus response
PDUs against an independent bank oracle. It checks unit, literal address,
quantity, ordered FC progression, exact write data and response transaction IDs.
Observation may begin at any FC but subsequent ordering must be:

```text
5, 1, 15, 2, 6, 3, 16, 4, repeat
```

Singles have quantity 1; other requests have quantity 4. FC5 writes ON (`0xFF00`),
FC15 writes four packed bits `[1, 0, 0, 0]` from the first word of the demo buffer,
FC6 writes `1`, and FC16 writes `[1, 0x1234, 0x5678, 0xabcd]`. Read replies reflect
the selected shared, separate or large map. Success requires at least `--cycles`
**verified emitted responses for every FC**, not merely accepted connections.
Wrong values/order/quantities or missing coverage at the deadline fail.

Run RTU and TCP PC servers concurrently under the **same** hardware lease when
checking the dual-transport client demo. Otherwise its other transport may time
out while this one runs. The host validates requests and replies it emits, not
whether the MCU consumed each reply correctly. Board-side completion/result
buffers need independent logs or instrumentation and stay `manual_pending`.
Fault injection of dropped replies, client reconnection and queue exhaustion is
not implemented by this observer; do not claim those gates passed.

## Running against a board: arbiter required

Do **not** run `python tools/modbus_verify.py ...` directly against connected
hardware from an unarbitrated shell. Have the parent session create an approved
wrapper under `.embedder/hardware/` and invoke it using `hardware_script_run`,
so the hardware lease covers the subprocess and all its traffic. The native
serial monitor must not own the same binary interface. No wrapper was created or
executed as part of this host-only deliverable. Run this suite against the
composite Modbus application, not upstream CDC echo or ECM connectivity baseline
images; their baseline acceptance checks are separate.

Example wrapper body (place it directly under `.embedder/hardware/`; select the
role/transport/profile/build arguments before approval):

```python
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[2]
argv = [
    str(root / ".venv/bin/python"), str(root / "tools/modbus_verify.py"),
    "board-server", "--transport", "tcp",
    "--profile", "shared", "--buffer-size", "128",
    "--host", "192.168.77.2", "--port", "502",
]
try:
    run = subprocess.run(argv, cwd=root, capture_output=True, text=True, timeout=180)
    result = json.loads(run.stdout)
    ok = run.returncode == 0 and result["success"]
    print(json.dumps({"success": ok, "summary": "PC Modbus checks",
                      "data": result, "stderr": run.stderr}))
except (subprocess.TimeoutExpired, OSError, ValueError) as exc:
    print(json.dumps({"success": False, "summary": str(exc)}))
```

The tool invocation names that saved wrapper with `script_name` and a sufficient
`timeout` (e.g. 240000 ms for the example). For soak runs use a background hardware
script and retain its task ID. For concurrent RTU/TCP PC servers the wrapper can
submit two bounded `subprocess.run` calls with `ThreadPoolExecutor(max_workers=2)`;
it must join both, check **both** exit codes/results, and print a single final
`success`/`summary` JSON line. Do not detach subprocesses from the leased script.
See [Embedder hardware scripts](https://docs.embedder.com/debug-mode/hardware-scripts).

Argument-list examples for that wrapper (not direct live shell commands):

```python
# Native CDC board server; supply the actual discovered path, never this placeholder.
["board-server", "--transport", "rtu", "--profile", "shared",
 "--buffer-size", "128", "--serial-port", "<confirmed native CDC port>"]

# Native CDC board client, identity selected after the composite identity is approved.
["board-client", "--transport", "rtu", "--profile", "separate",
 "--buffer-size", "256", "--usb-serial", "<confirmed unique USB serial>"]

# Large test-only board server, built with config/large-buffer.conf.
["board-server", "--transport", "tcp", "--profile", "large",
 "--buffer-size", "256", "--host", "192.168.77.2", "--port", "502"]

# TCP board client; firmware peer must match this already-configured listener.
["board-client", "--transport", "tcp", "--profile", "shared",
 "--buffer-size", "128", "--listen-host", "192.168.77.1", "--listen-port", "1502"]
```

For a >=1,000-exchange run, use `--iterations 40` for board-server (at least 1,132
positive PyModbus transactions per transport) or `--cycles 125` for board-client
(at least 1,000 verified responses per transport). Increase `--duration` and the
wrapper/tool deadlines according to the firmware query interval and timeouts;
60 seconds is a smoke-test window, not a guarantee of completing a long soak.
Save the JSON with `--json <result-path>`, alongside the actual firmware hash,
configuration/build evidence and selected endpoint identity in the parent report.

## Result contract

Normal completion prints exactly one JSON document on stdout; diagnostic logging
goes to stderr. `--json` additionally saves the same document. Exit 0 means all
executed automatic cases passed; exit 1 means a case/setup/output failure or
interruption. Invalid CLI input exits 2 with a JSON error on stderr. A file-output
failure is itself a failure, not a successful run with lost evidence.

Schema version 1 includes role, transport, endpoint, unit, profile, nominal
`buffer_size`, actual transport `adu_capacity`, shared `pdu_capacity`,
dependency versions, parameters, FC coverage, transaction counts, latency scope,
per-case results/details and aggregate counts. Case names and data patterns are
repeatable; elapsed times and measured latencies naturally vary. Transaction and
latency totals cover PyModbus interoperability exchanges, not additional raw
negative/framing traffic. PC-server latency is local request-to-response
processing, not board end-to-end latency. Raw cases report their exact outcome
and size separately. There is no silent conversion of failures into skips.

Every run records `usb_unplug_replug` and `no_terminal_cold_boot` as
`manual_pending`. `board-client` also records `board_client_result_buffers`.
`acceptance_complete` is always false: automatic protocol success is not full
physical USB/board acceptance. A valid >64-byte single ADU is explicitly skipped
for `shared`/`separate` and exercised for `large`. No-terminal boot, unplug/replug, real ECM enumeration,
physical 64-byte USB packet crossing and hardware timing are not proven by host
loopback or pseudo-terminal results.

## Host-only self-tests and present evidence

See [the harness usage README](../tests/tools/README.md) for a short entry point,
fixture descriptions and the approved client-demo/log contract.

Safe host-only invocation from the project root:

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -m pytest -q -p no:cacheprovider tests/tools
```

Recorded host result: **87 passed** on macOS with the versions above. This
includes 40-iteration TCP loopback runs with exactly 1,137 shared-map and 1,132
separate-map positive transactions; these are host results, not board soaks.

Fixtures use only loopback TCP sockets, fake serial transports, and paired host
pseudo-terminals. They exercise the **actual installed PyModbus client and server
APIs over TCP and RTU**, all three profiles and both buffer settings, plus malformed response/framing failures,
CRC golden vectors, binary writes without line endings, exact alias semantics,
request/response coverage, wrong writes, incomplete coverage, JSON failure exits,
serial identity ambiguity and all split/coalesced/four-client TCP cases. Deliberate
faulty peers prove that data mismatches, mutation and a fifth accepted client
are failures rather than passes. Large-profile fixtures inspect actual decoded
request/response sizes and quantities, verify the 73/77-byte FC16 transaction,
exercise 125-register/2,000-bit reads and 123-register/1,968-coil writes over both
transports with nominal 256, and detect malformed-write mutation even in the
final word of a multi-chunk map. Capacity regressions distinguish the nominal
setting, actual ADU size and MBAP Length field, and check rejection at one byte
over capacity for both settings.
Client-demo generators use independent approved function/address/data vectors;
regression checks pin both unit IDs, the PC endpoint, order and payloads rather
than deriving test expectations from the observer's own constants.

No board, USB cable, physical serial device or ECM interface is opened by these
tests. Real-target acceptance remains deferred until approved firmware, composite
USB identity, debug access and isolated ECM addressing are ready. Package
installation, firmware flashing and host network changes were not performed for
this harness.
