# D2 read audit: APROM support is NOT established

## 1. Scope and result

The saved NuvoISP_BL V1.04 host executable does not substantiate an APROM read
contract. Its two observed D2 producers read fixed CONFIG-space addresses using
4-byte or 8-byte requests. Neither accepts a caller-supplied target address.
There is no observed D2 call at APROM address zero, in the upper APROM half, or
in any APROM region. The ROM handler is not supplied by this host executable.

Consequently **an exact maximum D2 APROM length cannot be determined from this
EXE**. Four/eight bytes are the host's observed CONFIG read sizes; 52 bytes is the
single-response transport payload ceiling, NOT a demonstrated D2 read maximum.
No production generalized read API or live-backup permission follows from this
research. The recovery stop remains in effect, even after external ROM access
is established, until the missing target read contract is independently supplied.

Input identity (recomputed by audit_reads.py):

- ZIP SHA256: `4a7cfe5cd0207fa99f052ee1038b85c9110684cab9fb9fda2f594867c80ff5a7`.
- EXE SHA256: `aed05e31a6a73c760076218dcfbd038e94e579b0287bb86bb2add7ba8daa35f0`.
- PE virtual addresses below apply only to that EXE. Function names in this
  document are descriptive, not claimed exported symbols.
- No native EXE execution, Windows loader, USB calls, port opens, probe access,
  security writes, reset or target mutation occurred. Only analysis files in
  this directory were authored. The directory was absent and was created for
  the explicitly permitted evidence deliverable.

## 2. Complete observed D2 host producers

`read-routines.asm` contains disassembly starting at exact function boundaries.
`static-scan.json` records the code scan, every raw E8 reference to the encoder,
raw D2 pushes, and the absence of an absolute encoder pointer in the file.
Raw E8 scanning independently agrees with the linear disassembly's 13 encoder
call sites. This is evidence for the observed host paths, not a theorem ruling
out all dynamically constructed code or undocumented target commands.

### 0x0040A810: CONFIG words

Calling convention: this in ECX; arguments `(destination, signed_word_count)`.
The count controls the number of transactions, not their byte length or address
base. At 0x40A823 the routine unconditionally calls 0x40A6F0 (A0 identification),
even for count zero. Its return value is ignored. For i = 0..count-1:

- `offset = 4 * (i + (i >= 16 ? 16 : 0))` (0x40A830..0x40A849).
- D2 payload = little-endian uint32 address `0x0F300000 + offset`, then uint32
  length `4` (0x40A84B..0x40A85B).
- Encoder 0x40A040 called at 0x40A862 with command D2, payload size 8 and send
  timeout 20; request padding after these 8 bytes is zero.
- Receiver 0x4098D0 called at 0x40A87A with destination+offset, requested size 4,
  timeout 30000 and sequence checking disabled (`check_sequence=0`).

The normal caller supplies count 14 at 0x4090AB (identity worker) and at
0x408657 (operation dispatcher). Thus normal addresses end at 0x0F300034.
An emulated count 18 exercises the actual sparse jump from offset 0x3C to 0x80;
this does not make additional addresses supported on the physical target.

### 0x0040A8A0: CONFIG word pairs

Same arguments, but no A0 call. For i = 0,2,... while i < count:

- Same offset formula, D2 address `0x0F300000 + offset`, length `8`
  (0x40A8C0..0x40A8EB).
- Encoder at 0x40A8F2: payload size 8, timeout 20.
- Receiver at 0x40A90A: destination+offset, requested size 8, timeout 30000,
  sequence checking disabled.
- A positive odd count still reads a final full pair: count 19 emits 10 D2
  requests, ending at address 0x0F300088, covering bytes through 0x0F30008F.
  Count 1 reads 8 bytes, not 4. The sparse destination needs 144 bytes for
  count 19, not a dense 19-word/76-byte buffer.

Normal callers supply 19 at 0x4090D0 and 0x408709, in family-selected branches.
These other call sites do not turn either helper into an APROM API.

### Other commands and false-success hazards

The complete *successful* four-byte helper command sequence is A0, then D2 once
per word. The eight-byte helper issues only D2. Neither directly issues D1,
C0, C1, E1, B0, 5A or continuation command 00. Send failure invokes encoder's
host-close path 0x40A17D -> 0x409E30; there is no target command in that close
stub. Higher-level GUI connection/operation paths remain separate and must not
be reused as a read-only wrapper (see ../connection-audit/findings.txt).

Both helpers initialize aggregate success to one and skip the receive/AND when
send fails (0x40A869 -> 0x40A882; 0x40A8F9 -> 0x40A912). Thus a failed final/only
send can return success without copying anything. This is reproduced for the
8-byte helper with untouched 0xCC destination. The 4-byte helper also returns
success after a synthetically invalid A0 marker followed by successful D2.
Do not inherit either behavior in a safe client.

## 3. Exact response parsing and limits

0x4098D0 accepts `(destination, requested_length, timeout, check_sequence)`.
For USB mode, it delegates to 0x413920 at 0x40991F. That wrapper demands exactly
64 bytes returned by its HID read (comparison at 0x413962, with requested capacity
65 and comparison value 64). Lengths 0,1,12,63 and 65 fail in the emulator.
This analysis does not repeat or alter the earlier report-ID research.

After a successful transport read:

1. It requires at least 12 bytes (0x409976), then optionally validates the LE32
   response sequence at protocol offset 4 (0x40997B..0x40998B) against the
   current object sequence minus one. The encoder advances current sequence
   by 2 after successful transmission (0x40A16B), so response correlation is
   `(request_sequence + 1) modulo 2^32`.
2. Copy length is `min(requested_length, received_length - 12)`
   (0x40998D..0x409994), using an unsigned comparison. For USB, that is
   `min(requested_length, 52)`.
3. It copies from object+0x11 (protocol byte offset 12), into the destination
   (0x4099A1..0x4099A7). A normal 4-byte read is bytes 12..15, 8-byte read is
   bytes 12..19, and the maximum available payload is bytes 12..63.
4. It returns Boolean success, NOT number of bytes copied. Asking for 53, 56
   or UINT32_MAX still returns success after copying only 52. There is no
   reassembly, continuation transaction, or automatic next address.
5. There is no response checksum, returned-address, command-echo or status
   validation in this parser. Header bytes 0..3 and 8..11 remain uninterpreted;
   a synthetically arbitrary header passes. No invented checksum/status
   semantics can turn that into reliable backup validation.

The request encoder has a separate 56-byte payload limit at 0x40A06D..0x40A072.
That is unrelated to the D2 requested-memory-length field: D2 requests in this
EXE carry exactly 8 bytes regardless of whether the requested data length is
4 or 8. Do not confuse the limits 8, 52 and 56.

## 4. Reproducible CPU-only checks

Run from the project root:

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python \
  .embedder/hardware/results/boot-loader-v1.04/read-audit/audit_reads.py
```

Result: **25 cases passed**, saved in `emulation.json`.
The script executes allowlisted original x86 bytes for the two D2 helpers,
encoder, receiver, HID receive wrapper and A0 helper; all external interactions
terminate in bounded memory-only stubs. A0 is included only to establish the
extra command on the D2 helper path. No host HID library is imported.
Unexpected execution exits the allowlist with an error. Instruction/time budgets
bound each emulation. No target code is emulated or inferred.

Cases cover six helper/count combinations, exact addresses/lengths/zero padding,
sparse output copies, ignored A0 failure, false-success send failure, short
response rejection, nine parser lengths (0 through UINT32_MAX), five malformed
report lengths and stale sequence accepted/denied depending on the check flag.
The saved replies are synthetic byte patterns, never evidence of APROM contents.

## 5. Prerequisites for a later preserving 1-MiB backup

External ROM access alone is insufficient. Before enabling live traffic:

1. Obtain authoritative device-side evidence for the exact M3351KJCAE ROM
   revision that D2 (or a different explicitly read-only command) reads APROM,
   including its address map/aliases, maximum per-request size, alignment,
   reply/error/status meaning, protection behavior and target-side side effects.
   A host CONFIG caller and successful arbitrary-address encoding do not supply
   this. No unlock, erase, security transition or reset may be assumed necessary.
2. Explicitly authorize the selected transport/target once external access is
   established. Match PDID 0x03302140 and independently established KJ geometry;
   do not derive APROM size from undocumented A0 fields. Prevent concurrent
   traffic. Do not reuse the vendor GUI connect or operation dispatcher.
3. Enforce a command allowlist, checked current sequence, exact transfer sizes,
   finite timeout and immediate fail-closed behavior. No automatic retry, reopen,
   re-identification, reset, bridge setup or write fallback. Preserve raw request
   and reply evidence for diagnosing ambiguous/error replies. The target's
   unresolved error/status semantics must be resolved, not masked by a parser.
4. Only after the contract is known, plan explicit bounded chunks covering
   `[0x00000000, 0x00100000)` exactly, with integer/overflow/alignment checks and
   a correctly sized final chunk. Record address and actual returned length for
   each; never pad missing data or treat parser Boolean success as byte count.
   Neither 4-, 8- nor 52-byte APROM chunks are approved by this audit.
5. Save a fresh exact 1,048,576-byte image, manifest and hashes; reread independently
   and compare every byte, including 0x00080000..0x000FFFFF and boundary chunks.
   Require device-side evidence excluding error-fill, aliasing or inaccessible
   memory; repeated identical 0xFF/0x00 data alone does not establish validity.
   Partial/mismatching acquisitions stay explicitly incomplete and stop recovery.
6. APROM alone does not satisfy project preservation requirements: separately
   establish read contracts and save LDROM, Data Flash and documented CONFIG
   snapshots before any write is contemplated. Keep the historical lower-half
   backup separate. No write/erase/reset authorization is implied by backup work.
