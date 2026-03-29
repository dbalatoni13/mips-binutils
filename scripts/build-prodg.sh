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
: "${CFLAGS:=-std=gnu89 -w -fcommon}"
: "${CXXFLAGS:=-std=gnu++98 -w -fcommon}"
: "${LDFLAGS:=}"
: "${MAKE:=make}"
: "${BISON:=bison}"
: "${BISONFLAGS:=}"

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

rm -rf "$PREFIX"
mkdir -p "$PREFIX"

libiberty_args=(
  --prefix="$PREFIX"
)

if [[ -n "${HOST_TRIPLE:-}" ]]; then
  libiberty_args+=(--host="$HOST_TRIPLE")
fi

if [[ -n "${BUILD_TRIPLE:-}" ]]; then
  libiberty_args+=(--build="$BUILD_TRIPLE")
fi

cd "${SOURCE_ROOT}/libiberty"
env \
  CC="$CC" \
  CFLAGS="$CFLAGS" \
  LDFLAGS="$LDFLAGS" \
  ./configure "${libiberty_args[@]}"

"$MAKE" -j"$MAKE_JOBS" \
  CC="$CC" \
  CFLAGS="$CFLAGS" \
  LDFLAGS="$LDFLAGS" \
  libiberty.a

cd "${SOURCE_ROOT}/gcc"

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
  ./configure "${configure_args[@]}"

"$MAKE" -j"$MAKE_JOBS" \
  CC="$CC" \
  CXX="$CXX" \
  BUILD_CC="$BUILD_CC" \
  BUILD_CXX="$BUILD_CXX" \
  BISON="$BISON" \
  BISONFLAGS="$BISONFLAGS" \
  CFLAGS="$CFLAGS" \
  CXXFLAGS="$CXXFLAGS" \
  LDFLAGS="$LDFLAGS" \
  cc1 cc1plus cpp gcc-cross g++-cross collect2 c++filt specs

bindir="${PREFIX}/bin"
libsubdir="${PREFIX}/lib/gcc-lib/${TARGET_TRIPLE}"
toolbindir="${PREFIX}/${TARGET_TRIPLE}/bin"

mkdir -p "$bindir" "$libsubdir" "$toolbindir"

install -m 755 gcc-cross "${bindir}/${TARGET_TRIPLE}-gcc"
install -m 755 gcc-cross "${toolbindir}/gcc"
install -m 755 g++-cross "${bindir}/${TARGET_TRIPLE}-g++"
ln -sf "${TARGET_TRIPLE}-g++" "${bindir}/${TARGET_TRIPLE}-c++"

for compiler in cc1 cc1plus cpp; do
  install -m 755 "${compiler}" "${libsubdir}/${compiler}"
done

if [[ -f collect2 ]]; then
  install -m 755 collect2 "${libsubdir}/collect2"
  install -m 755 xgcc "${libsubdir}/gcc"
fi

if [[ -f c++filt ]]; then
  install -m 755 c++filt "${bindir}/${TARGET_TRIPLE}-c++filt"
fi

install -m 644 specs "${libsubdir}/specs"
