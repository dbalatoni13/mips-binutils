ARG ALPINE_VERSION=3.20.6
FROM alpine:${ALPINE_VERSION} AS build

RUN apk add --no-cache \
    bash \
    binutils \
    build-base \
    curl \
    patch \
    perl \
    python3 \
    unzip \
    xz

ARG ZIG_VERSION=0.13.0
RUN mkdir /zig && \
    curl -L "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-$(uname -m)-${ZIG_VERSION}.tar.xz" | \
    tar -xJ -C /zig --strip-components=1
ENV PATH="/zig:${PATH}"

WORKDIR /src
COPY . .

ARG GNU_TRIPLE
ARG ZIG_TRIPLE
RUN PREFIX=/target \
    WORKDIR=/tmp/prodg \
    HOST_TRIPLE="${GNU_TRIPLE}" \
    CC="zig cc -target ${ZIG_TRIPLE}" \
    CXX="zig c++ -target ${ZIG_TRIPLE}" \
    BUILD_CC="cc" \
    BUILD_CXX="c++" \
    ./scripts/build-prodg.sh

FROM scratch AS export
COPY --from=build /target .
