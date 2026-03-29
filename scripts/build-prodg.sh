#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

: "${PREFIX:=${REPO_ROOT}/build}"
: "${WORKDIR:=${REPO_ROOT}/work}"
: "${TARGET_TRIPLE:=powerpc-eabi}"
: "${CC:=cc}"
: "${CXX:=c++}"
: "${BUILD_CC:=cc}"
: "${BUILD_CXX:=c++}"
: "${CFLAGS:=-std=gnu89 -w}"
: "${CXXFLAGS:=-std=gnu++98 -w}"
: "${LDFLAGS:=}"
: "${MAKE:=make}"

if command -v nproc >/dev/null 2>&1; then
  MAKE_JOBS=${MAKE_JOBS:-$(nproc)}
elif command -v getconf >/dev/null 2>&1; then
  MAKE_JOBS=${MAKE_JOBS:-$(getconf _NPROCESSORS_ONLN)}
elif command -v sysctl >/dev/null 2>&1; then
  MAKE_JOBS=${MAKE_JOBS:-$(sysctl -n hw.ncpu)}
else
  MAKE_JOBS=${MAKE_JOBS:-1}
fi

"${SCRIPT_DIR}/prepare-prodg-source.sh" "${WORKDIR}/source" "${WORKDIR}/downloads" >/dev/null

SOURCE_ROOT="${WORKDIR}/source/NGC_GNU_SRC/NGC"
BUILD_ROOT="${WORKDIR}/build"

rm -rf "$BUILD_ROOT" "$PREFIX"
mkdir -p "$BUILD_ROOT" "$PREFIX"
cd "$BUILD_ROOT"

configure_args=(
  --target="$TARGET_TRIPLE"
  --prefix="$PREFIX"
  --disable-nls
  --enable-languages=c,c++
  --without-headers
)

if [[ -n "${HOST_TRIPLE:-}" ]]; then
  configure_args+=(--host="$HOST_TRIPLE")
fi

if [[ -n "${BUILD_TRIPLE:-}" ]]; then
  configure_args+=(--build="$BUILD_TRIPLE")
fi

env \
  CC="$CC" \
  CXX="$CXX" \
  BUILD_CC="$BUILD_CC" \
  BUILD_CXX="$BUILD_CXX" \
  CFLAGS="$CFLAGS" \
  CXXFLAGS="$CXXFLAGS" \
  LDFLAGS="$LDFLAGS" \
  "${SOURCE_ROOT}/gcc/configure" "${configure_args[@]}"

"$MAKE" -j"$MAKE_JOBS" \
  CC="$CC" \
  CXX="$CXX" \
  BUILD_CC="$BUILD_CC" \
  BUILD_CXX="$BUILD_CXX" \
  CFLAGS="$CFLAGS" \
  CXXFLAGS="$CXXFLAGS" \
  LDFLAGS="$LDFLAGS" \
  native gcc-cross specs stmp-headers

"$MAKE" \
  CC="$CC" \
  CXX="$CXX" \
  BUILD_CC="$BUILD_CC" \
  BUILD_CXX="$BUILD_CXX" \
  CFLAGS="$CFLAGS" \
  CXXFLAGS="$CXXFLAGS" \
  LDFLAGS="$LDFLAGS" \
  install-headers install-common install-driver
