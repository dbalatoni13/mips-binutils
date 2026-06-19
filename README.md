Cross-platform builds of GNU GCC 8.5.0 for the PowerPC 750CL.

The toolchain targets `powerpc-eabi`, defaults to `-mcpu=750 -mtune=750`, and
includes GCC's upstream paired-single backend. Pass `-mpaired` when compiling
code that uses the 750CL paired-single instruction set.

Each artifact contains GCC's C and C++ frontends. The compiler is freestanding:
it does not include binutils, a C library, `libgcc`, or a C++ standard library.
Install a compatible `powerpc-eabi` assembler and linker separately when
producing object files or executables.

The CI matrix produces:

- Linux: statically linked musl binaries for x86_64, i686, armv7l, and aarch64
- macOS: universal x86_64/arm64
- Windows: x86_64
