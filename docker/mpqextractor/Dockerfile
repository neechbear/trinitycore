# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

FROM debian:jessie
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq -o Dpkg::Use-Pty=0 update && \
    apt-get -qq -o Dpkg::Use-Pty=0 install -y --no-install-recommends \
    software-properties-common python-software-properties \
 < /dev/null > /dev/null

RUN add-apt-repository ppa:nicolaw/blip && \
    sed -i 's/jessie/trusty/g' /etc/apt/sources.list.d/nicolaw-blip-jessie.list

# https://github.com/Kanma/MPQExtractor
RUN apt-get -qq -o Dpkg::Use-Pty=0 update && \
    apt-get -qq -o Dpkg::Use-Pty=0 install -y --no-install-recommends \
    blip \
    cmake \
    g++ \
    gcc \
    git \
    make \
    zlib1g-dev \
    libbz2-dev \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /

COPY build.sh /
RUN chmod +x /build.sh

VOLUME /artifacts

ENV DEBIAN_FRONTEND newt

ENTRYPOINT ["/build.sh"]
CMD ["-o", "/artifacts"]

