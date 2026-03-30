Cross-platform CI builds of the SN Systems ProDG 3.9.3 `Dolphin` GCC toolchain binaries for Linux, macOS, and Windows.

The Linux artifact is built in a glibc-based container so the produced host tools run on typical mainstream Linux distributions.

The installed `CPP` binary is built from ProDG's standalone `NGC/CPP` source set, then wired into the configured GCC build so its preprocessor behavior stays closer to the original ProDG toolchain.

Windows artifacts are built for both 32-bit and 64-bit MinGW hosts.
The 32-bit artifact is intended for wrapper-based setups such as `wibo`, and its `cpp.exe` binary is patched after build to avoid the unsupported `AreFileApisANSI` import path.
