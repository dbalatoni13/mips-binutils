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
export CFLAGS="${CFLAGS:--std=gnu89 -w -fcommon}"
export CXXFLAGS="${CXXFLAGS:--std=gnu++98 -w -fcommon}"

./scripts/build-prodg.sh
