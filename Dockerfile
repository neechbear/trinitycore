# MIT License
# Copyright (c) 2017-2021 Nicola Worthington <nicolaw@tfb.net>

FROM debian:10 AS build
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DEBIAN_FRONTEND noninteractive

# https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
# https://trinitycore.atlassian.net/wiki/display/tc/Requirements
RUN apt-get -qq -o Dpkg::Use-Pty=0 update \
 && apt-get -qq -o Dpkg::Use-Pty=0 install --no-install-recommends -y \
    bc \
    ca-certificates \
    clang \
    cmake \
    curl \
    default-libmysqlclient-dev \
    g++ \
    gcc \
    git \
    jq \
    make \
    p7zip \
    libboost-all-dev \
    libssl-dev \
    libmariadbclient-dev \
    libreadline-dev \
    zlib1g-dev \
    libbz2-dev \
    libncurses-dev \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/* \
 && update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 \
 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100

RUN curl -sSL https://github.com/neechbear/blip/releases/download/v0.10/blip-0.10.tar.gz \
 | tar -zxvf - \
 && cd blip-0.10/ \
 && make install prefix=/usr

ENV DEBIAN_FRONTEND newt

COPY build.sh /
RUN /bin/bash -c /build.sh



