Cross-platform CI builds of the SN Systems ProDG 3.9.3 `Dolphin` GCC toolchain binaries for Linux, macOS, and Windows.

The Linux artifact is built in a glibc-based container so the produced host tools run on typical mainstream Linux distributions.

The installed `CPP` binary is built from ProDG's standalone `NGC/CPP` source set, then wired into the configured GCC build so its preprocessor behavior stays closer to the original ProDG toolchain.

Windows artifacts are built for both 32-bit and 64-bit MinGW hosts.
The 32-bit host compiler now defaults to `-O3`, with `cp/decl.c` forced to `-O1` to avoid the `cc1plus.exe` ICE reproduced by `nfsmw`.
The 32-bit artifact is intended for wrapper-based setups such as `wibo`, and its `cpp.exe` binary is patched after build to avoid the unsupported `AreFileApisANSI` import path.

The repo also includes `scripts/patch-rodata-stock.py`, a pure-Python PE patcher for stock frontend binaries. It currently supports:

- ProDG 3.9.3 GameCube `cc1.exe`
- ProDG 3.9.3 GameCube `cc1plus.exe`
- PS2 EE 2.9-ee-991111 `cc1.exe`
- PS2 EE 2.9-ee-991111 `cc1plus.exe`

Use `python3 scripts/patch-rodata-stock.py --list` to see the available profiles, then:

`python3 scripts/patch-rodata-stock.py <profile> <input.exe> [output.exe]`

The patcher recreates the rodata-object behavior from patch `0018`, adding `.type` / `.size` metadata and, for the GameCube frontends, renaming emitted constant labels from `.LC*` to `LC*` so references keep matching.
