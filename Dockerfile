# MIT License
# Copyright (c) 2017-2021 Nicola Worthington <nicolaw@tfb.net>

# TODO: Different image tag flavours:
#   debug <- unstripped, extra debug with source (perhaps with SQL?)
#   full <- stripped with source
#   slim <- default (latest aliases slim)
#
# TODO: Patch default /etc/{auth,world}server.conf to not write log files and
#       have other sensible defaults that might work out of the box with an
#       example docker-compose.yaml that could bring up all the servers and a
#       MySQL server.
#
# TODO: Add more helpful labels that include vcs-url and suggested Docker
#       command line run examples.
#
# TODO: Setup automatic CI pipeline to make a nightly build and publish to
#       DockerHub.
#
# TODO: Include helper command to pull and extract the latest TDB_full SQL
#       archive files.
#
# TODO: Include a help command to extract all the height maps.

FROM debian:buster-slim AS build

ENV DEBIAN_FRONTEND noninteractive

# https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
# https://trinitycore.atlassian.net/wiki/display/tc/Requirements
RUN apt-get -qq -o Dpkg::Use-Pty=0 update \
 && apt-get -qq -o Dpkg::Use-Pty=0 install --no-install-recommends -y \
    binutils \
    ca-certificates \
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
# TODO: See https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml for debug builds.
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
ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu PATH=/bin:/usr/bin:/opt/trinitycore/bin
COPY --from=build /artifacts /

