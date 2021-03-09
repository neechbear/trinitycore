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
#
# TODO: CloudFormation template to deploy into AWS EC2, with or without RDS.
#       Requires client MPQ resources to be uploaded to S3 bucket.

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

RUN mkdir -pv /build/
WORKDIR /build
# TODO: See https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml for debug builds.
# TODO: Perhaps get some of these values (or augment them) from build args?
RUN cmake ../src -DTOOLS=1 -DWITH_WARNINGS=0 -DCMAKE_INSTALL_PREFIX=/opt/trinitycore -DCONF_DIR=/etc -Wno-dev
RUN make -j$(nproc)
RUN make install

RUN find /build -ls

RUN mkdir -pv /artifacts/ && tar -cf - --exclude=**/sql/old/** /usr/bin/mysql /opt/trinitycore /src/sql /etc/*server.conf.dist | tar -C /artifacts/ -xvf -
RUN ldd /artifacts/opt/trinitycore/bin/* /usr/bin/mysql | grep ' => ' | tr -s '[:blank:]' '\n' | grep '^/' | sort -u | \
    xargs -I % sh -c 'mkdir -pv $(dirname /artifacts%); cp -v % /artifacts%'

WORKDIR /artifacts
# TODO: Optionally don't strip for debug builds.
RUN strip opt/trinitycore/bin/*
RUN mv -v etc/authserver.conf.dist etc/authserver.conf
RUN mv -v etc/worldserver.conf.dist etc/worldserver.conf


FROM busybox:stable-glibc AS slim
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

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
LABEL org.label-schema.docker.cmd.worldserver="docker run --rm -p 8085:8085 -p 3443:3443 -p 7878:7878 -v \$PWD/worldserver.conf:/etc/worldserver.conf -d nicolaw/trinitycore:3.3.5-slim worldserver"
LABEL org.label-schema.docker.cmd.authserver="docker run --rm -p 3724:3724 -v \$PWD/authserver.conf:/etc/authserver.conf -d nicolaw/trinitycore:3.3.5-slim authserver"
LABEL org.label-schema.docker.cmd.mapextractor="docker run --rm -v \$PWD/World_of_Warcraft:/wow -v \$PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-slim mapextractor -i /wow -o /mapdata -e 7 -f 0"
LABEL org.label-schema.docker.cmd.vmap4extractor="docker run --rm -v \$PWD/World_of_Warcraft:/wow -v \$PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-slim vmap4extractor -l -d /wow/Data"
LABEL org.label-schema.docker.cmd.vmap4assembler="docker run --rm -v \$PWD/World_of_Warcraft:/wow -v \$PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-slim vmap4assembler /mapdata/Buildings /mapdata/vmaps"
LABEL org.label-schema.docker.cmd.mmaps_generator="docker run --rm -v \$PWD/World_of_Warcraft:/wow -v \$PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-slim mmaps_generator"

ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu PATH=/bin:/usr/bin:/opt/trinitycore/bin
COPY --from=build /artifacts /

