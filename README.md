Cross-platform CI builds of the SN Systems ProDG 3.9.3 `Dolphin` GCC toolchain binaries for Linux, macOS, and Windows.

The Linux artifact is built in a glibc-based container so the produced host tools run on typical mainstream Linux distributions.
The Windows artifact is built as a 32-bit MinGW toolchain so wrapper-based setups can run the compiler image without requiring Wine.
Its `cpp.exe` binary is patched after build so the toolchain works under `wibo` without the unsupported `AreFileApisANSI` import path.
