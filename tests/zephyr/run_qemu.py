#!/usr/bin/env python3
"""Run this qemu_cortex_m3 ztest ELF without Twister's optional Python packages.

Only starts an emulated lm3s6965evb. It never accesses a probe or real target.
Zephyr's ztest success/failure banner, not merely process launch, is the verdict.
"""
import argparse
import os
import selectors
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("elf")
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--qemu", default="qemu-system-arm")
    args = parser.parse_args()
    command = [args.qemu, "-machine", "lm3s6965evb", "-cpu", "cortex-m3",
               "-nographic", "-monitor", "none", "-serial", "stdio",
               "-nic", "none", "-kernel", args.elf]
    success = False
    output = bytearray()
    with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT) as process:
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(process.stdout, selectors.EVENT_READ)
                deadline = time.monotonic() + args.timeout
                while True:
                    remaining = deadline - time.monotonic()
                    if remaining <= 0 or not selector.select(remaining):
                        print("QEMU test timed out", file=sys.stderr)
                        break
                    chunk = os.read(process.stdout.fileno(), 4096)
                    if not chunk:
                        break
                    sys.stdout.buffer.write(chunk)
                    sys.stdout.buffer.flush()
                    output.extend(chunk)
                    if b"PROJECT EXECUTION FAILED" in output or b"FATAL ERROR" in output:
                        break
                    if b"PROJECT EXECUTION SUCCESSFUL" in output:
                        success = True
                        break
        finally:
            process.terminate()
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
