#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

: "${PREFIX:=${REPO_ROOT}/build}"
: "${WORKDIR:=${REPO_ROOT}/work}"
: "${CONFIG_TARGET_TRIPLE:=powerpc-eabi}"
: "${TARGET_TRIPLE:=Dolphin}"
: "${CC:=cc}"
: "${CXX:=c++}"
: "${BUILD_CC:=cc}"
: "${BUILD_CXX:=c++}"
: "${CFLAGS:=-O1 -std=gnu89 -w -fcommon}"
: "${CXXFLAGS:=-O1 -std=gnu++98 -w -fcommon}"
: "${LDFLAGS:=}"
: "${MAKE:=make}"
: "${BISON:=bison}"
: "${BISONFLAGS:=}"

exeext=
build_collect2=true
case "${HOST_TRIPLE:-$(uname -s)}" in
  *mingw*|*MINGW*|*msys*|*MSYS*)
    exeext=.exe
    build_collect2=false
    ;;
  *cygwin*|*CYGWIN*)
    exeext=.exe
    ;;
esac

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
  --target="$CONFIG_TARGET_TRIPLE"
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

build_targets=(
  "cc1${exeext}"
  "cc1plus${exeext}"
  "cpp${exeext}"
  gcc-cross
  "g++-cross${exeext}"
  "c++filt${exeext}"
  specs
)

if [[ "${build_collect2}" == true ]]; then
  build_targets+=("collect2${exeext}")
fi

"$MAKE" -j"$MAKE_JOBS" \
  CC="$CC" \
  CXX="$CXX" \
  BUILD_CC="$BUILD_CC" \
  BUILD_CXX="$BUILD_CXX" \
  target_alias="$TARGET_TRIPLE" \
  BISON="$BISON" \
  BISONFLAGS="$BISONFLAGS" \
  CFLAGS="$CFLAGS" \
  CXXFLAGS="$CXXFLAGS" \
  LDFLAGS="$LDFLAGS" \
  "${build_targets[@]}"

bindir="${PREFIX}/bin"
libsubdir="${PREFIX}/lib/gcc-lib/${TARGET_TRIPLE}"
toolbindir="${PREFIX}/${TARGET_TRIPLE}/bin"

mkdir -p "$bindir" "$libsubdir" "$toolbindir"

install -m 755 "gcc-cross${exeext}" "${bindir}/${TARGET_TRIPLE}-gcc${exeext}"
install -m 755 "gcc-cross${exeext}" "${toolbindir}/gcc${exeext}"
install -m 755 "g++-cross${exeext}" "${bindir}/${TARGET_TRIPLE}-g++${exeext}"
if [[ -n "${exeext}" ]]; then
  install -m 755 "g++-cross${exeext}" "${bindir}/${TARGET_TRIPLE}-c++${exeext}"
else
  ln -sf "${TARGET_TRIPLE}-g++" "${bindir}/${TARGET_TRIPLE}-c++"
fi

for compiler in cc1 cc1plus cpp; do
  install -m 755 "${compiler}${exeext}" "${libsubdir}/${compiler}${exeext}"
done

if [[ -f "xgcc${exeext}" ]]; then
  install -m 755 "xgcc${exeext}" "${libsubdir}/gcc${exeext}"
fi

if [[ -f "collect2${exeext}" ]]; then
  install -m 755 "collect2${exeext}" "${libsubdir}/collect2${exeext}"
fi

if [[ -f "c++filt${exeext}" ]]; then
  install -m 755 "c++filt${exeext}" "${bindir}/${TARGET_TRIPLE}-c++filt${exeext}"
fi

install -m 644 specs "${libsubdir}/specs"
