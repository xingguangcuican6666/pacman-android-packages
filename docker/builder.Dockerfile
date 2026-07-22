FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        clang \
        cmake \
        curl \
        file \
        git \
        jq \
        libarchive-tools \
        lld \
        llvm \
        make \
        meson \
        ninja-build \
        patch \
        patchelf \
        pkg-config \
        python3 \
        rsync \
        unzip \
        xz-utils \
        zip \
        zstd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

CMD ["/bin/bash"]
