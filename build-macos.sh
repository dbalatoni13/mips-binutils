#!/bin/bash -ex

export CFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=11.0"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=11.0"

exec ./scripts/build-toolchain.sh
