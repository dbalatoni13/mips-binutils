#!/bin/bash -ex
PREFIX="$(pwd)/build"
mkdir source
wget -qO- https://mirror.netcologne.de/gnu/binutils/binutils-2.45.tar.xz | tar -xJ -C source --strip-components=1
cd source
./configure --target=mips-linux-gnu --prefix="$PREFIX" --disable-nls --disable-gprof --without-zstd
make -j$(nproc) configure-host
make -j$(nproc)
make install-strip
