#!/usr/bin/env python3

import struct
import subprocess
import sys
from pathlib import Path


PATCH_BYTES = bytes.fromhex("B8 01 00 00 00 C3")
SYMBOL = "___mingw_filename_cp"


def symbol_va(path: Path) -> int:
    output = subprocess.check_output(["nm", "-a", str(path)], text=True)
    for line in output.splitlines():
        if line.endswith(f" T {SYMBOL}"):
            return int(line.split()[0], 16)
    raise RuntimeError(f"symbol {SYMBOL!r} not found in {path}")


def file_offset_for_va(data: bytes, va: int) -> int:
    pe_offset = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe_offset : pe_offset + 4] != b"PE\0\0":
        raise RuntimeError("not a PE executable")

    magic = struct.unpack_from("<H", data, pe_offset + 24)[0]
    if magic != 0x10B:
        raise RuntimeError(f"unsupported PE magic 0x{magic:x}")

    image_base = struct.unpack_from("<I", data, pe_offset + 24 + 28)[0]
    rva = va - image_base

    section_count = struct.unpack_from("<H", data, pe_offset + 6)[0]
    optional_size = struct.unpack_from("<H", data, pe_offset + 20)[0]
    section_offset = pe_offset + 24 + optional_size

    for index in range(section_count):
        offset = section_offset + 40 * index
        virtual_size, virtual_address, raw_size, raw_pointer = struct.unpack_from(
            "<IIII", data, offset + 8
        )
        span = max(virtual_size, raw_size)
        if virtual_address <= rva < virtual_address + span:
            return raw_pointer + (rva - virtual_address)

    raise RuntimeError(f"RVA 0x{rva:x} is not mapped in any section")


def patch(path: Path) -> None:
    data = bytearray(path.read_bytes())
    offset = file_offset_for_va(data, symbol_va(path))
    current = bytes(data[offset : offset + len(PATCH_BYTES)])
    if current == PATCH_BYTES:
        return
    data[offset : offset + len(PATCH_BYTES)] = PATCH_BYTES
    path.write_bytes(data)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} <cpp.exe>", file=sys.stderr)
        return 2

    patch(Path(sys.argv[1]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
