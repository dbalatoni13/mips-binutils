# Build stage
ARG ALPINE_VERSION=3.19.1
FROM alpine:${ALPINE_VERSION} AS build

ARG GCC_VERSION=8.5.0
ARG TARGET=powerpc-eabi

RUN apk add --no-cache \
    bash \
    bison \
    build-base \
    flex \
    gmp-dev \
    mpc1-dev \
    mpfr-dev \
    patch \
    texinfo \
    wget \
    xz

RUN wget -q "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"

COPY gcc-*.patch /

RUN mkdir /src-gcc && \
    tar -xf "/gcc-${GCC_VERSION}.tar.xz" -C /src-gcc --strip-components=1 && \
    cd /src-gcc && \
    for file in /gcc-*.patch; do patch -N -p1 -i "${file}"; done && \
    mkdir /build-gcc && \
    cd /build-gcc && \
    /src-gcc/configure \
        --target="${TARGET}" \
        --prefix=/target \
        --with-cpu=750 \
        --with-tune=750 \
        --without-headers \
        --enable-languages=c,c++ \
        --disable-bootstrap \
        --disable-assembly \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libstdcxx-pch \
        --disable-multilib \
        --disable-nls \
        --disable-shared \
        --disable-threads && \
    make -j"$(nproc)" all-gcc && \
    make install-strip-gcc

# Export toolchain (usage: docker build --target export --output build .)
FROM scratch AS export
COPY --from=build /target .
