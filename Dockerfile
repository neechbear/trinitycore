# MIT License
# Copyright (c) 2017-2021 Nicola Worthington <nicolaw@tfb.net>

# TODO: Setup automatic CI pipeline to make a nightly build and publish to
#       DockerHub.

ARG FLAVOUR=slim

FROM debian:buster-slim AS build

ENV DEBIAN_FRONTEND noninteractive

# https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
# https://trinitycore.atlassian.net/wiki/display/tc/Requirements
RUN apt-get -qq -o Dpkg::Use-Pty=0 update \
 && apt-get -qq -o Dpkg::Use-Pty=0 install --no-install-recommends -y \
    p7zip \
    binutils \
    ca-certificates \
    clang \
    cmake \
    curl \
    default-mysql-client \
    default-libmysqlclient-dev \
    g++ \
    gcc \
    git \
    jq \
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

# TODO: Perhaps get these values from build args (with 3.3.5 sensible defaults)?
RUN git clone --branch 3.3.5 --single-branch --depth 1 https://github.com/TrinityCore/TrinityCore.git /src

# TODO: Add debug options to Dockerfile multistage build debug tag flavour.
#  if [[ "${cmdarg_cfg[debug]}" == true ]]; then
#    # https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
#    # https://trinitycore.atlassian.net/wiki/display/tc/Linux+Core+Installation
#    define[WITH_WARNINGS]=1
#    define[WITH_COREDEBUG]=0 # What does this do, and why is it 0 on a debug build?
#    define[CMAKE_BUILD_TYPE]="Debug"
#    define[CMAKE_C_FLAGS]="-Werror"
#    define[CMAKE_CXX_FLAGS]="-Werror"
#    define[CMAKE_C_FLAGS_DEBUG]="-DNDEBUG"
#    define[CMAKE_CXX_FLAGS_DEBUG]="-DNDEBUG"
#  fi
#  if [[ "${define[WITH_WARNINGS]}" == "0" ]]; then
#    extra_cmake_args+=("-Wno-dev")
#  fi

RUN mkdir -pv /build/ /artifacts/
WORKDIR /build
# TODO: See https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml for debug builds.
# TODO: Perhaps get some of these values (or augment them) from build args?
RUN cmake ../src -DTOOLS=1 -DWITH_WARNINGS=0 -DCMAKE_INSTALL_PREFIX=/opt/trinitycore -DCONF_DIR=/etc -Wno-dev
RUN make -j$(nproc)
RUN make install

ADD https://raw.githubusercontent.com/bells17/wait-for-it-for-busybox/master/wait-for-it.sh /bin/wait-for-it.sh
RUN chmod +x /bin/wait-for-it.sh

ARG FLAVOUR=slim
ENV FLAVOUR=${FLAVOUR}

WORKDIR /artifacts

RUN tar -cf - /usr/bin/mysql /opt/trinitycore /etc/*server.conf.dist | tar -C /artifacts/ -xvf - \
 && if [ "x$FLAVOUR" = "xsql" ] || [ "x$FLAVOUR" = "xfull" ] ; then tar -cf - /src/sql | tar -C /artifacts/ -xvf - ; fi \
 && if [ "x$FLAVOUR" = "xfull" ] ; then tar -cf - --exclude=**build/dep/** --exclude=**build/src/** /src /build /usr/bin/curl /usr/bin/cmake | tar -C /artifacts/ -xvf - ; fi
RUN ldd opt/trinitycore/bin/* usr/bin/* | grep ' => ' | tr -s '[:blank:]' '\n' | grep '^/' | sort -u | \
    xargs -I % sh -c 'mkdir -pv $(dirname .%); cp -v % .%'
RUN strip opt/trinitycore/bin/*
#RUN mv -v etc/authserver.conf.dist etc/authserver.conf
#RUN mv -v etc/worldserver.conf.dist etc/worldserver.conf

RUN if [ "x$FLAVOUR" = "xsql" ] || [ "x$FLAVOUR" = "xfull" ] ; then \
 curl -Lo TDB_full_world.7z "$(curl -sSL https://api.github.com/repos/TrinityCore/TrinityCore/releases \
    | jq -r --arg tag TDB335 '[.[]|select(.tag_name|contains($tag))|select(.assets[0].browser_download_url|endswith(".7z")).assets[].browser_download_url]|max')" \
 && 7zr x -y -osrc/sql -- TDB_full_world.7z \
 && rm -fv TDB_full_world.7z \
 && ln -s src/sql/TDB_full_world_*.sql \
 ; fi



FROM busybox:stable-glibc
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ARG FLAVOUR
ARG BUILD_DATE
ARG VCS_REF
ARG BUILD_VERSION

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="nicolaw/trinitycore"
LABEL org.label-schema.description="TrinityCore MMO Framework"
LABEL org.label-schema.usage="https://github.com/neechbear/trinitycore/blob/master/README.md"
LABEL org.label-schema.url="https://nicolaw.uk/trinitycore/"
LABEL org.label-schema.vcs-url="https://github.com/NeechBear/trinitycore"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vendor="Nicola Worthington"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd.worldserver="docker run --rm -p 8085:8085 -p 3443:3443 -p 7878:7878 -v \$PWD/worldserver.conf:/etc/worldserver.conf -d nicolaw/trinitycore:3.3.5-${FLAVOUR} worldserver"
LABEL org.label-schema.docker.cmd.authserver="docker run --rm -p 3724:3724 -v \$PWD/authserver.conf:/etc/authserver.conf -d nicolaw/trinitycore:3.3.5-${FLAVOUR} authserver"
LABEL org.label-schema.docker.cmd.mapextractor="docker run --rm -v \$PWD/World_of_Warcraft:/wow -v \$PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-${FLAVOUR} mapextractor -i /wow -o /mapdata -e 7 -f 0"
LABEL org.label-schema.docker.cmd.vmap4extractor="docker run --rm -v \$PWD/World_of_Warcraft:/wow -v \$PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-${FLAVOUR} vmap4extractor -l -d /wow/Data"
LABEL org.label-schema.docker.cmd.vmap4assembler="docker run --rm -v \$PWD/World_of_Warcraft:/wow -v \$PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-${FLAVOUR} vmap4assembler /mapdata/Buildings /mapdata/vmaps"
LABEL org.label-schema.docker.cmd.mmaps_generator="docker run --rm -v \$PWD/World_of_Warcraft:/wow -v \$PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-${FLAVOUR} mmaps_generator"

ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu PATH=/bin:/usr/bin:/opt/trinitycore/bin
COPY --from=build /artifacts /

