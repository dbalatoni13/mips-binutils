#!/bin/bash -ex

GCC_VERSION="${GCC_VERSION:-8.5.0}"
TARGET="${TARGET:-powerpc-eabi}"
ROOT="$(pwd)"
PREFIX="${PREFIX:-${ROOT}/build}"
JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu)}"

download()
{
  local url="$1"
  local output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 -o "${output}" "${url}"
  else
    wget -O "${output}" "${url}"
  fi
}

rm -rf source-gcc build-gcc
mkdir source-gcc build-gcc

download \
  "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz" \
  "gcc-${GCC_VERSION}.tar.xz"
tar -xf "gcc-${GCC_VERSION}.tar.xz" -C source-gcc --strip-components=1

download \
  "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess" \
  config.guess
download \
  "https://git.savannah.gnu.org/cgit/config.git/plain/config.sub" \
  config.sub
find source-gcc -name config.guess -exec cp config.guess {} \;
find source-gcc -name config.sub -exec cp config.sub {} \;

(
  cd source-gcc
  for file in ../gcc-*.patch; do
    patch -N -p1 -i "${file}"
  done

  for archive in \
    gmp-6.1.0.tar.bz2 \
    mpfr-3.1.4.tar.bz2 \
    mpc-1.0.3.tar.gz
  do
    download \
      "https://gcc.gnu.org/pub/gcc/infrastructure/${archive}" \
      "${archive}"
  done
  ./contrib/download_prerequisites --no-isl
)

(
  cd build-gcc
  ../source-gcc/configure \
    --target="${TARGET}" \
    --prefix="${PREFIX}" \
    --with-cpu=750 \
    --with-tune=750 \
    --without-headers \
    --enable-languages=c,c++ \
    --disable-bootstrap \
    --disable-assembly \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libstdcxx-pch \
    --disable-multilib \
    --disable-nls \
    --disable-shared \
    --disable-threads
  make -j"${JOBS}" all-gcc
  make install-strip-gcc
)
