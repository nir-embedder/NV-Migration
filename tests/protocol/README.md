# Portable protocol host tests

These tests compile only `lib/modbus/Src/ModbusCore.c` and the host fixtures.
They need CMake, a host C11 compiler, and Ninja (or another CMake generator),
not Zephyr, hardware, network access, or a Modbus Python package.

From the project root on macOS:

```sh
cmake -S tests/protocol -B tests/protocol/build -G Ninja \
  -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_BUILD_TYPE=Debug \
  -DMODBUS_SANITIZERS=ON
cmake --build tests/protocol/build
ctest --test-dir tests/protocol/build --output-on-failure
```

AddressSanitizer and UndefinedBehaviorSanitizer are **on by default**; Clang or
GCC is required when enabled. Warnings (`-Wall -Wextra -Wpedantic -Wconversion
-Wshadow`) are errors. Tests use their own always-active checks, so a Release
build cannot disable validation through `NDEBUG`.

For detailed assertion totals, use `ctest --test-dir tests/protocol/build -V`.
A single suite can be run with `tests/protocol/build/protocol_tests <suite>`.

## Coverage matrix

| CTest suite | Scope |
| --- | --- |
| `protocol.golden_server` | Hand-specified request/reply and bank vectors for FC1/2/3/4/5/6/15/16, including FC5 off; separate and in-place PDU buffers; canaries; illegal FC. |
| `protocol.golden_client` | Hand-specified master request encoding and response decoding for every FC; zero/nonzero FC5 convention; packed words; FC15 output padding; unused read bits; canaries. |
| `protocol.maps` | Independent nonzero-base coil/DI/HR/IR regions; non-word-aligned coil base; isolated writes; first/last/out-of-range addresses; per-region NULL fallback ignoring stale metadata; NULL/empty banks; shared-bank aliasing. |
| `protocol.server_bounds` | Spec maxima and zero/max+1/65535 quantities; all insufficient reply capacities; exact bank ends; address-space wrap; no mutation on failure; null arguments; 128/256-byte ADU-capacity profiles. |
| `protocol.client_validation` | Query quantity/address/capacity checks; all insufficient request capacities; every truncated response prefix with exact-size allocation; trailing data; wrong FC; all wrong byte counts; every echoed field; exception FC/length/code matching; canaries; 128/256-byte profiles. |
| `protocol.crc` | `123456789 -> 0x4b37`, known RTU request `01 03 00 00 00 0a -> 0xcdc5`, low/high wire-byte residue, all single-bit corruptions, empty and >255-byte inputs. |
| `protocol.rtu_lengths` | All 256 FC bytes, both directions, every header prefix length 0–8 with exact allocations; all byte-count values; exceptions, unknown functions, coalesced frames, 256-byte limit. |
| `protocol.exhaustive_bits` | All 2,080 nonempty start/count ranges in a 64-bit bank; independent bit-by-bit read/write oracle; preservation outside written range; last-word clearing; canaries. |
| `protocol.randomized` | 12,000 deterministic valid build/server/parse transactions across all FCs and randomized separate-region starts; independent expected bank mutations and decoded-data checks. |
| `protocol.malformed` | All 65,534 invalid FC5 values; every truncated request prefix and trailing byte; every wrong FC15/16 byte count; 24,000 deterministic arbitrary byte streams through server/parser/length inference using exact-size heap allocations; failed operations preserve bank/data. |

The fixtures do not rely solely on round trips: the golden PDUs, memory changes,
bit oracle and malformed-input expectations are independently specified.
`randomized` and `malformed` use the reproducible xorshift32 seed `0x9c022fd2`.

The PDU core intentionally has no unit, CRC-verification or MBAP ownership.
Unit filtering, corrupt-frame rejection, broadcast/no-response behavior, stream
recovery/partial I/O, cancellation, queueing, transaction IDs and USB/network
interoperability require their transport/runtime suites and are not claimed here.

## Measured results (2026-10-28)

On macOS arm64, Apple Clang **21.0.0 (clang-2100.1.1.101)**:

- Debug build with **ASAN + UBSAN**: **10/10 suites passed**, **4,190,764 checks**;
  no sanitizer reports or compiler warnings.
- Optimized Release build without sanitizers: **10/10 suites passed**.
- Clang static analyzer on `ModbusCore.c`: completed with no diagnostics.
- Clang source-based coverage on the same ASAN/UBSAN suites:
  **26/26 functions, 416/416 lines, 365/365 regions**, and **265/268 branches
  (98.88%)**. The three unexecuted false branches are lower-bound FC checks
  (`function >= MB_FC_READ_COILS`) after unsupported functions have already been
  rejected; they are not missing valid-function test cases. This is coverage,
  not proof of full correctness or a safety/compliance certification.

Logs from a local run are under `build/Testing/Temporary/LastTest.log`.
Build and coverage artifacts stay in ignored `build*` directories.

### Reproduce optional source coverage

Use a fresh build directory for an independent coverage run:

```sh
cmake -S tests/protocol -B tests/protocol/build-coverage -G Ninja \
  -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_BUILD_TYPE=Debug \
  -DMODBUS_SANITIZERS=ON \
  '-DCMAKE_C_FLAGS=-fprofile-instr-generate -fcoverage-mapping'
cmake --build tests/protocol/build-coverage
LLVM_PROFILE_FILE="$PWD/tests/protocol/build-coverage/%p.profraw" \
  ctest --test-dir tests/protocol/build-coverage --output-on-failure
xcrun llvm-profdata merge -sparse tests/protocol/build-coverage/*.profraw \
  -o tests/protocol/build-coverage/core.profdata
xcrun llvm-cov report tests/protocol/build-coverage/protocol_tests \
  -instr-profile=tests/protocol/build-coverage/core.profdata \
  lib/modbus/Src/ModbusCore.c
```

The coverage toolchain comes with the installed Apple command-line tools; no
packages are installed by these tests. On Linux, use the matching `llvm-profdata`
and `llvm-cov` binaries directly instead of `xcrun`.

### Optional optimized build and static analyzer

```sh
cmake -S tests/protocol -B tests/protocol/build-release -G Ninja \
  -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_BUILD_TYPE=Release \
  -DMODBUS_SANITIZERS=OFF
cmake --build tests/protocol/build-release
ctest --test-dir tests/protocol/build-release --output-on-failure
/usr/bin/clang --analyze -std=c11 -I lib/modbus/Inc \
  -Xanalyzer -analyzer-output=text lib/modbus/Src/ModbusCore.c
```
