# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

FROM debian:jessie
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq -o Dpkg::Use-Pty=0 update && \
    apt-get -qq -o Dpkg::Use-Pty=0 install -y --no-install-recommends \
    libboost-filesystem1.55 \
    libboost-iostreams1.55 \
    libboost-program-options1.55 \
    libboost-system1.55 \
    libboost-thread1.55 \
    libssl1.0.0 \
    libmysqlclient18 \
    mysql-client \
    netcat \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

# Configurable via INSTALL_PREFIX from the Makefile, and/or using
# --define CMAKE_INSTALL_PREFIX=/your/path with the docker/build/ container,
# (which is also published on Ducker Hub as nicolaw/trinitycore).
ENV install_prefix /opt/trinitycore

# https://trinitycore.atlassian.net/wiki/display/tc/Databases+Installation
# Database import of TDB_*.sql files, astonishingly, requires that the
# current working directory be the same path as the location of both the
# worldserver binary and the TDB_*.sql file.
WORKDIR "${install_prefix}/bin"

# Wait for the database server to come up first.
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh "${install_prefix}/bin/wait-for-it.sh"

# Add worldserver binary and wrapper, and make executable.
COPY worldserver.sh "${install_prefix}/bin/worldserver.sh"
COPY worldserver "${install_prefix}/bin/worldserver"
RUN chmod +x "${install_prefix}/bin"/*

# Add TDB_*.sql database dump for initial world database initialisation.
ADD TDB_*.sql "${install_prefix}/bin/"

ENV DEBIAN_FRONTEND newt

ENTRYPOINT ["./worldserver.sh"]

