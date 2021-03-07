# MIT License
# Copyright (c) 2017-2020 Nicola Worthington <nicolaw@tfb.net>

FROM debian:10
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq -o Dpkg::Use-Pty=0 update \
 && apt-get -qq -o Dpkg::Use-Pty=0 install -y --no-install-recommends \
    bc \
    ca-certificates \
    curl \
    libboost-filesystem1.67.0 \
    libboost-iostreams1.67.0 \
    libboost-program-options1.67.0 \
    libboost-regex1.67.0 \
    libboost-system1.67.0 \
    libboost-thread1.67.0 \
    libmariadb3 \
    libssl1.1 \
    make \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://github.com/neechbear/blip/releases/download/v0.10/blip-0.10.tar.gz \
 | tar -zxvf - \
 && cd blip-0.10/ \
 && make install prefix=/usr

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

ENV DEBIAN_FRONTEND newt

ENTRYPOINT ["/tools.sh"]
CMD ["-o", "/artifacts", "-i", "/World_of_Warcraft"]

