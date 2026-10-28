# Pinned CDC ACM driver regression

```sh
QEMU_BIN=/opt/homebrew/bin/qemu-system-arm sh tests/cdc/run.sh
```

Uses the existing `.venv`, Zephyr SDK and `tests/zephyr/run_qemu.py` (no installs
or live hardware). `run.sh` applies/verifies the revision-pinned project patch
before building. Both system and dedicated CDC workqueues run the same tests.
The result is the actual ztest `PROJECT EXECUTION SUCCESSFUL` banner, not merely
an ELF build or QEMU launch. Each queue currently runs 20 tests.

`src/main.c` includes the **actual** `.deps/zephyr/subsys/usb/device_next/class/
usbd_cdc_acm.c` compilation unit. It calls its real class API, UART API, work
handlers and preinit against real Zephyr FIFOs, spinlocks, workqueues, semaphores,
threads and net_buf pools. Only the USB/UDC ownership boundary and USB message
publication are mocked; no copied purge/generation helper is tested instead.
The qemu board has no CDC devicetree instance, so the real file's DT registration
macro emits no additional device. CMake supplies its class-local configuration.

Coverage:

- No-terminal enumeration starts RX and TX without DTR.
- Buffered RX and retained TX disappear on close; delayed successful/error
  completions remain owned by USB until returned and cannot seed a new session.
- Rapid DTR low/high (with USB messages deliberately never delivered), repeated
  closes, configuration disable/re-enable, and 40 reconnect cycles per run.
- Real callback/close and enqueue/close interleavings; close from the UART callback
  cannot deadlock; class disable from IRQ only queues sleeping cleanup.
- UART FIFO backpressure while closed, polling with flow control, and fresh RX
  through the real UART FIFO after reopening.
- FIFO-fill under a caller spinlock does not invoke the sleeping UDC; full-buffer
  TX runs later on the workqueue and preserves all payload bytes.
- A real 64-byte TX payload already removed from the UDC queue, whose delayed
  success must keep reopen gated until completion; the next payload contains
  only new bytes. Partly consumed RX is also purged.
- Exact 128- and 256-byte FIFO streams across multiple 64-byte buffers, plus
  polling-only recovery without a registered IRQ callback.
- Synchronous and delayed dequeue completions, failed dequeue (fail closed),
  failed enqueue and accurate pool accounting.
- Notification submission concurrent with close and notification completion
  before the sender waits; cancelled notifications wake with `-ECANCELED`.

Recorded follow-up verification (2026-10-28): 20/20 cases passed for each
workqueue, plus five additional complete runs per workqueue (200 repeat cases).
The unchanged Modbus integration matrix passed all 64 cases at nominal sizes
128 and 256, and the host harness passed all 87 cases. Those checks preserve the
RTU B / TCP B+4 contract (128/132 and 256/260); the CDC stream test itself does
not impose Modbus framing or change protocol capacity. The target server build
also passed with the same SDK patch and unchanged firmware hash.

This validates the class correction, not the physical Nuvoton UDC, electrical
connection, ECM traffic, or host OS. Physical unplug/replug and simultaneous
RTU/TCP behavior remain the parent's live-hardware checks.
