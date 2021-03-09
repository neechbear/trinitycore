# MIT License
# Copyright (c) 2017-2021 Nicola Worthington <nicolaw@tfb.net>

FROM debian:buster-slim AS build

ENV DEBIAN_FRONTEND noninteractive

# https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
# https://trinitycore.atlassian.net/wiki/display/tc/Requirements
RUN apt-get -qq -o Dpkg::Use-Pty=0 update \
 && apt-get -qq -o Dpkg::Use-Pty=0 install --no-install-recommends -y \
    binutils \
    clang \
    cmake \
    default-mysql-client \
    default-libmysqlclient-dev \
    g++ \
    gcc \
    git \
    make \
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

RUN git clone --branch 3.3.5 --single-branch https://github.com/TrinityCore/TrinityCore.git /src

RUN mkdir -pv /build/
WORKDIR /build
RUN cmake ../src -DTOOLS=1 -DWITH_WARNINGS=0 -DCMAKE_INSTALL_PREFIX=/opt/trinitycore -DCONF_DIR=/etc -Wno-dev
RUN make -j$(nproc)
RUN make install

RUN mkdir -pv /artifacts/ && tar -cf - /usr/bin/mysql /opt/trinitycore /etc/*server.conf.dist | tar -C /artifacts/ -xvf -
RUN ldd /artifacts/opt/trinitycore/bin/* /usr/bin/mysql | grep ' => ' | tr -s '[:blank:]' '\n' | grep '^/' | sort -u | \
    xargs -I % sh -c 'mkdir -pv $(dirname /artifacts%); cp -v % /artifacts%'

WORKDIR /artifacts
RUN strip opt/trinitycore/bin/*
RUN mv -v etc/authserver.conf.dist etc/authserver.conf
RUN mv -v etc/worldserver.conf.dist etc/worldserver.conf


FROM busybox:stable-glibc AS slim
LABEL author="Nicola Worthington <nicolaw@tfb.net>"
ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu PATH=/bin:/opt/trinitycore/bin
COPY --from=build /artifacts /

