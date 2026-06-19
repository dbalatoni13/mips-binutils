#!/bin/bash -ex

export CFLAGS="-O1"
export CXXFLAGS="-O1"

exec ./scripts/build-toolchain.sh
