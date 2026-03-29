ARG ALPINE_VERSION=3.20.6
FROM alpine:${ALPINE_VERSION} AS build

RUN apk add --no-cache \
    bash \
    bison \
    binutils \
    build-base \
    curl \
    flex \
    gperf \
    patch \
    perl \
    python3 \
    unzip \
    xz

WORKDIR /src
COPY . .

RUN PREFIX=/target \
    WORKDIR=/tmp/prodg \
    ./scripts/build-prodg.sh

FROM scratch AS export
COPY --from=build /target .
