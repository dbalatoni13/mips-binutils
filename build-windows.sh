#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$(pwd)/build}"
WORKDIR="${WORKDIR:-$(pwd)/work}"

export PREFIX
export WORKDIR
export HOST_TRIPLE="${HOST_TRIPLE:-x86_64-w64-mingw32}"
export CC="${CC:-clang}"
export CXX="${CXX:-clang++}"
export BUILD_CC="${BUILD_CC:-clang}"
export BUILD_CXX="${BUILD_CXX:-clang++}"
export CFLAGS="${CFLAGS:--std=gnu89 -w}"
export CXXFLAGS="${CXXFLAGS:--std=gnu++98 -w}"

./scripts/build-prodg.sh
