#!/bin/bash -ex

export CFLAGS="-O1"
export CXXFLAGS="-O1"
export LDFLAGS="-static -static-libgcc -static-libstdc++"

exec ./scripts/build-toolchain.sh
