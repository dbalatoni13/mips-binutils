ARG DEBIAN_VERSION=bullseye-slim
FROM debian:${DEBIAN_VERSION} AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bison \
    binutils \
    build-essential \
    ca-certificates \
    curl \
    flex \
    gperf \
    patch \
    perl \
    python3 \
    unzip \
    xz-utils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN PREFIX=/target \
    WORKDIR=/tmp/prodg \
    ./scripts/build-prodg.sh

FROM scratch AS export
COPY --from=build /target .
