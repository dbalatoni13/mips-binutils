#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$(pwd)/build}"
WORKDIR="${WORKDIR:-$(pwd)/work}"

export PREFIX
export WORKDIR
export HOST_TRIPLE="${HOST_TRIPLE:-i686-w64-mingw32}"
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export BUILD_CC="${BUILD_CC:-gcc}"
export BUILD_CXX="${BUILD_CXX:-g++}"

case "${HOST_TRIPLE}" in
  i686-*-mingw*|i686-*-msys*)
    host_opt_level="${WINDOWS_X86_BASE_OPT_LEVEL:-O3}"
    host_opt_level="${host_opt_level#-}"
    default_cflags="-${host_opt_level} -std=gnu89 -w -fcommon"
    default_cxxflags="-${host_opt_level} -std=gnu++98 -w -fcommon"
    export HOST_O1_SOURCES="${HOST_O1_SOURCES:-cp/decl.c}"
    ;;
  *)
    default_cflags="-O2 -fno-strict-aliasing -std=gnu89 -w -fcommon"
    default_cxxflags="-O2 -fno-strict-aliasing -std=gnu++98 -w -fcommon"
    ;;
esac

export CFLAGS="${CFLAGS:-$default_cflags}"
export CXXFLAGS="${CXXFLAGS:-$default_cxxflags}"

./scripts/build-prodg.sh

case "${HOST_TRIPLE}" in
  i686-*-mingw*|i686-*-msys*)
    python3 ./scripts/patch-wibo-cpp.py "${PREFIX}/lib/gcc-lib/Dolphin/cpp.exe"
    ;;
esac
