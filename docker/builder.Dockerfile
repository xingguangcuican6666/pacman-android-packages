FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        wget \
        gnupg \
        file \
        rsync \
        git \
        jq \
        unzip \
        zip \
        xz-utils \
        zstd \
        libarchive-tools \
        tar \
        cpio \
        build-essential \
        clang \
        lld \
        llvm \
        cmake \
        make \
        meson \
        ninja-build \
        pkg-config \
        patch \
        patchelf \
        gawk \
        bison \
        flex \
        m4 \
        gettext \
        texinfo \
        autoconf \
        automake \
        libtool \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        python3-setuptools \
        python3-wheel \
        libssl-dev \
        zlib1g-dev \
        libffi-dev \
        libsqlite3-dev \
        libbz2-dev \
        liblzma-dev \
        libzstd-dev \
        libreadline-dev \
        libncurses-dev \
        libxml2-dev \
        libxslt1-dev \
        libclang-dev \
        bc \
        kmod \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

CMD ["/bin/bash"]