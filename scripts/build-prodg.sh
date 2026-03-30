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
: "${CFLAGS:=-O2 -fno-strict-aliasing -std=gnu89 -w -fcommon}"
: "${CXXFLAGS:=-O2 -fno-strict-aliasing -std=gnu++98 -w -fcommon}"
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

apply_host_source_opt_overrides() {
  local gcc_makefile=$1
  local cp_makefile=$2

  if [[ -z "${HOST_O0_SOURCES:-}" && -z "${HOST_O1_SOURCES:-}" ]]; then
    return
  fi

  python3 - "$gcc_makefile" "$cp_makefile" <<'PY'
from pathlib import Path
import os
import re
import sys

gcc_makefile = Path(sys.argv[1])
cp_makefile = Path(sys.argv[2])

begin = "# BEGIN host source opt overrides"
end = "# END host source opt overrides"
opt_flags = ("-O0", "-O1", "-O2", "-O3", "-Og", "-Os")
entries = {}

def parse_sources(raw):
    for item in re.split(r"[\s,]+", raw.strip()):
        if item:
            yield item

def object_name(source):
    name = Path(source).name
    for suffix in (".c", ".cc", ".cpp", ".cxx", ".C", ".o"):
        if name.endswith(suffix):
            return name[: -len(suffix)] + ".o" if suffix != ".o" else name
    return name + ".o"

for env_name, opt_flag in (("HOST_O0_SOURCES", "-O0"), ("HOST_O1_SOURCES", "-O1")):
    for source in parse_sources(os.environ.get(env_name, "")):
        makefile = cp_makefile if source.startswith("cp/") else gcc_makefile
        entries[(makefile, object_name(source))] = (source, opt_flag)

for makefile in (gcc_makefile, cp_makefile):
    if not makefile.exists():
        continue

    text = makefile.read_text()
    if begin in text and end in text:
        start = text.index(begin)
        finish = text.index(end, start) + len(end)
        text = text[:start].rstrip() + "\n"

    lines = []
    for (path, obj), (source, opt_flag) in sorted(entries.items()):
        if path != makefile:
            continue
        filter_expr = " ".join(opt_flags)
        lines.append(f"# {source}")
        lines.append(
            f"{obj}: ALL_CFLAGS := $(filter-out {filter_expr},$(ALL_CFLAGS)) {opt_flag}"
        )

    if not lines:
        makefile.write_text(text)
        continue

    block = "\n".join([begin, *lines, end])
    makefile.write_text(text.rstrip() + "\n\n" + block + "\n")
PY

  echo "Applied host source optimization overrides:"
  [[ -n "${HOST_O0_SOURCES:-}" ]] && echo "  -O0: ${HOST_O0_SOURCES}"
  [[ -n "${HOST_O1_SOURCES:-}" ]] && echo "  -O1: ${HOST_O1_SOURCES}"
}

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

apply_host_source_opt_overrides "${SOURCE_ROOT}/gcc/Makefile" "${SOURCE_ROOT}/gcc/cp/Makefile"

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
