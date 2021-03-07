# MIT License
# Copyright (c) 2017-2020 Nicola Worthington <nicolaw@tfb.net>

FROM debian:10
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq -o Dpkg::Use-Pty=0 update \
 && apt-get -qq -o Dpkg::Use-Pty=0 install -y --no-install-recommends \
    libboost-filesystem1.67.0 \
    libboost-iostreams1.67.0 \
    libboost-program-options1.67.0 \
    libboost-regex1.67.0 \
    libboost-system1.67.0 \
    libboost-thread1.67.0 \
    libmariadb3 \
    libssl1.1 \
    netcat \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

# Configurable via INSTALL_PREFIX from the Makefile, and/or using
# --define CMAKE_INSTALL_PREFIX=/your/path with the docker/build/ container,
# (which is also published on Ducker Hub as nicolaw/trinitycore).
ENV install_prefix /opt/trinitycore

WORKDIR "${install_prefix}/bin"
VOLUME "${install_prefix}/etc"

# Wait for the database server to come up first.
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh "${install_prefix}/bin/wait-for-it.sh"
COPY authserver.sh "${install_prefix}/bin/authserver.sh"
COPY authserver "${install_prefix}/bin/authserver"

RUN chmod +x "${install_prefix}/bin"/*

ENV DEBIAN_FRONTEND newt

ENTRYPOINT ["./authserver.sh"]

