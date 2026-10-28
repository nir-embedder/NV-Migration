# Upstream-derived portable Modbus core

## Source and license

This is a port of **alejoseb/Modbus-STM32-HAL-FreeRTOS**, not Zephyr's Modbus
implementation or an independently attributed replacement.

- Repository: <https://github.com/alejoseb/Modbus-STM32-HAL-FreeRTOS>
- Immutable revision: `9c022fd2538edb5b53e2e07c98ebbe9a4685546c`
- Commit subject: `Cap Modbus response size check to MAX_BUFFER, not a hardcoded 256`
- Original sources: `MODBUS-LIB/Src/Modbus.c`, `MODBUS-LIB/Inc/Modbus.h`
- Local reference checkout: `.deps/modbus-upstream` (relative to project root).
- The upstream source and header identify **Alejandro Mera**, May 5, 2020.
  The source additionally credits adaptation from
  <https://github.com/smarmengol/Modbus-Master-Slave-for-Arduino>.
- `LICENSE` is an unmodified copy of upstream's GNU Lesser General Public
  License, version 2.1. The port retains LGPL-2.1 licensing and does not relicense
  the derived library under Apache/MIT. SPDX tags use `LGPL-2.1-only` without
  assuming an additional upstream "or later" declaration.
- `ModbusCore.c` and `ModbusCore.h` are modified versions for NV-Migration,
  dated **2026-10-28**. Original author/adaptation credits are retained.

SHA-256 of the pristine inputs at the revision above:

| File | SHA-256 |
| --- | --- |
| `MODBUS-LIB/Src/Modbus.c` | `b8a7d1eb955a3bbf794586d9b12d50bdf72f94032a222813a6e435c034ef7422` |
| `MODBUS-LIB/Inc/Modbus.h` | `6d07baa939de5cbe1451ffaa6421ba795d79c3fe81a03a966edb15fdfc0066d9` |
| `LICENSE` | `20c17d8b8c48a600800dfd14f95d5cb9ff47066a9641ddeab48dc54aec96e331` |

Redistributors must retain notices and license, identify modifications, and
provide the applicable library source. For a linked firmware distribution,
address LGPL section 6's relinking requirements (for example, the application
object files and build/link materials needed to relink against a modified
library), applicable installation requirements, and license notices. Providing
only a binary or this provenance file is not enough. Consult the actual license
for the full obligations; this paragraph is not a substitute.

## Actual derivation map

Line references below refer to the pinned upstream **Modbus.c**, not a floating
branch. Header references explicitly identify **Modbus.h**.

| Original code | Ported location / retained logic |
| --- | --- |
| `Modbus.h:52–62`, `153–167`, `199–225` | `ModbusCore.h`: original FC enum names, telegram fields, shared/optional separate memory arrays and their address/word-count semantics. HAL/RTOS handler state is excluded. |
| `109–114`, `230–287`: `mb_region_t`, `getCoilsRegion`, `getDIRegion`, `getHRRegion`, `getIRRegion` | Same internal type/helper names and conditional field selection in `ModbusCore.c`; each NULL separate pointer independently falls back to zero-based shared memory. |
| `1570–1719`: `validateRequest`; server dispatch `877–925` | `mb_core_server`: FC dispatch, region selection, start-relative offsets and bit-to-word range formula. Transport CRC/address handling is removed; exact shape, quantity and capacity checks precede dispatch. |
| `1970–2020`: `process_FC1` (FC1/2) | `process_FC1`: region-relative coil index, `/16` word and `%16` bit, LSB-first response bit stream. Response initialization also guarantees zero padding. |
| `2031–2057`: `process_FC3` (FC3/4) | `process_FC3`: consecutive region-relative words emitted high byte then low byte. |
| `2067–2096`: `process_FC5` | `process_FC5`: relative coil address divided into word/bit, update only that bit; server returns exact five-byte PDU echo. |
| `2106–2124`: `process_FC6` | `process_FC6`: decode high/low request word, write relative holding-register address and echo. |
| `2134–2184`: `process_FC15` | `process_FC15`: retain per-coil loop, advancing byte/bit indices, relative packed-bank writes; echo address and quantity. |
| `2194–2223`: `process_FC16` | `process_FC16`: per-register high/low extraction into consecutive relative holding registers; echo address and quantity. |
| `1054–1153`: `SendQuery` | `mb_core_build`: original function switch, address/count header, FC5 zero/nonzero input convention, FC15 low/high bytes of packed uint16 words, FC16 big-endian word loop. No sending or scheduler state. |
| `1433–1449`: `get_FC1`; `1457–1467`: `get_FC3`; `1477–1522`: `validateAnswer` | `mb_core_parse` plus `get_FC1/get_FC3`: retain low/high packed coil-byte combination and big-endian register extraction. Replace response validation with query-correlated, exact-size checks before any destination update. |
| `1727–1734`: `word`; `1745–1768`: `calcCRC`; `1777–1785`: `buildException` | Same helper roles: shift-based endian-independent word construction; same seeded `0xffff`/reflected `0xa001` CRC loop; function high bit and exception code. CRC's final numeric swap is omitted as described below. |

`mb_rtu_frame_length` is new stream-boundary inference, not an upstream function.
It derives ADU length from the supported function shapes. It does **not** verify
CRC, unit ID, quantity, byte count consistency, or complete-frame availability.

## Intentional boundary and safety changes

- Core entry points consume/produce **PDUs only** (no unit, MBAP, or CRC).
  Unit filtering, broadcast eligibility/suppression, CRC checks, transaction IDs,
  scheduling, serialization, deadlines and stream ownership belong to the caller.
  The caller must lock shared banks when accessed concurrently.
- No STM32, FreeRTOS, lwIP, Zephyr, global handler, heap, or global buffer limit is
  present in the core. `size_t` lengths and `int` results replace upstream's
  overflowing eight-bit frame lengths/results.
- Capacity is explicit. A caller's 128-byte RTU ADU buffer allows 125 PDU bytes;
  a 256-byte ADU buffer allows 253. The core itself applies protocol limits, not
  a compile-time profile. Insufficient response/output/data space returns
  `-ENOSPC` **before** any bank or caller output mutation.
- FC1/2 quantities: 1–2000 bits; FC3/4: 1–125 words; FC15: 1–1968 bits;
  FC16: 1–123 words. Client FC5/6 require `u16CoilsNo == 1`. Address plus quantity
  cannot cross 65536, even when a configured region has more allocated storage.
- Malformed server requests produce exception 3; unsupported FCs exception 1;
  unavailable/out-of-range banks exception 2. All supported requests require
  exact length. FC5 accepts only `0x0000` or `0xff00` on wire. FC15/16 must have
  exactly the quantity-derived byte count and complete payload. Padding bits in
  FC15 are ignored. No failed request partly updates a bank.
- A non-NULL region with zero size remains an empty region, not a fallback.
  Bit-region starts need not be multiples of 16; offsets are relative to the
  selected region, as upstream. A NULL shared array is an unavailable bank.
- Queries have caller-provided `u16regCapacity` in **words**. Bit arrays remain
  packed uint16 words. Build checks read-destination as well as write-source
  capacity before any source access; it emits zero FC15 padding bits.
- Parse checks matching FC, exact shape, exact byte count and all echoed
  address/value/quantity fields before changing data. Correctly matched two-byte
  exceptions return the nonzero exception code. Read-coil unused high bits of
  the last word are cleared, rather than retaining stale upstream contents;
  incoming padding bits are ignored. Only required words are touched.
- `calcCRC` returns the conventional **numeric** CRC16/Modbus, e.g.
  `"123456789" -> 0x4b37`. Put `crc & 0xff` first and `crc >> 8` second on wire.
  Upstream returned a byte-swapped integer, then emitted its high byte first;
  the wire order is unchanged. Input is const; length is `size_t`.
- Input/output PDU buffers may be identical for server in-place processing.
  PDU storage must not alias the query or memory-bank arrays. Query metadata and
  write-source words remain valid and unchanged through response parsing.
- Length inference reads only present header bytes. Incomplete headers return
  zero; unknown normal FCs return `-ENOTSUP`. Any high-bit exception response
  is structurally five ADU bytes. Inferred lengths over 256 return `-EMSGSIZE`.
  Multiple buffered frames do not change the first frame's expected length.

## Verification

Host-only tests and reproducible commands are in `../../tests/protocol/README.md`.
These establish portable protocol behavior, not Zephyr integration, USB
enumeration, electrical timing, or physical target interoperability.
