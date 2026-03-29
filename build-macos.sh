#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$(pwd)/build}"
WORKDIR="${WORKDIR:-$(pwd)/work}"

export PREFIX
export WORKDIR
export CC="${CC:-clang}"
export CXX="${CXX:-clang++}"
export BUILD_CC="${BUILD_CC:-clang}"
export BUILD_CXX="${BUILD_CXX:-clang++}"
export CFLAGS="${CFLAGS:--arch arm64 -arch x86_64 -mmacosx-version-min=10.13 -std=gnu89 -w -fcommon}"
export CXXFLAGS="${CXXFLAGS:--arch arm64 -arch x86_64 -mmacosx-version-min=10.13 -std=gnu++98 -w -fcommon}"

./scripts/build-prodg.sh
