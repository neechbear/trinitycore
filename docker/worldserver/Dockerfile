# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

FROM debian:jessie
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Use-Pty=0 install \
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

ENV install_prefix /opt/trinitycore

WORKDIR "${install_prefix}"

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh "${install_prefix}/bin/wait-for-it.sh"
COPY worldserver.sh "${install_prefix}/bin/worldserver.sh"
COPY worldserver "${install_prefix}/bin/worldserver"

RUN chmod +x "${install_prefix}/bin"/*

ENTRYPOINT ["bin/worldserver.sh"]

