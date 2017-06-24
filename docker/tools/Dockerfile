# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

FROM debian:jessie
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Use-Pty=0 install \
    software-properties-common python-software-properties \
 < /dev/null > /dev/null

RUN add-apt-repository ppa:nicolaw/blip && \
    sed -i 's/jessie/trusty/g' /etc/apt/sources.list.d/nicolaw-blip-jessie.list

RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Use-Pty=0 install \
    blip \
    libboost-filesystem1.55 \
    libboost-iostreams1.55 \
    libboost-program-options1.55 \
    libboost-system1.55 \
    libboost-thread1.55 \
    libssl1.0.0 \
    libmysqlclient18 \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

ENV install_prefix /opt/trinitycore
ENV PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${install_prefix}/bin"

WORKDIR "${install_prefix}/bin"

COPY tools.sh /tools.sh

COPY mapextractor "${install_prefix}/bin/mapextractor"
COPY mmaps_generator "${install_prefix}/bin/mmaps_generator"
COPY vmap4assembler "${install_prefix}/bin/vmap4assembler"
COPY vmap4extractor "${install_prefix}/bin/vmap4extractor"

RUN chmod +x "${install_prefix}/bin"/* /tools.sh

VOLUME /artifacts

ENTRYPOINT ["/tools.sh"]
CMD ["-o", "/artifacts", "-i", "/World_of_Warcraft"]

