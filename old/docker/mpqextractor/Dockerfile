# MIT License
# Copyright (c) 2017-2020 Nicola Worthington <nicolaw@tfb.net>

FROM debian:10
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DEBIAN_FRONTEND noninteractive

# https://github.com/Kanma/MPQExtractor
RUN apt-get -qq -o Dpkg::Use-Pty=0 update \
 && apt-get -qq -o Dpkg::Use-Pty=0 install -y --no-install-recommends \
    bc \
    clang \
    cmake \
    curl \
    g++ \
    gcc \
    git \
    make \
    zlib1g-dev \
    libbz2-dev \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/* \
 && update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 \
 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100

RUN curl -sSL https://github.com/neechbear/blip/releases/download/v0.10/blip-0.10.tar.gz \
 | tar -zxvf - \
 && cd blip-0.10/ \
 && make install prefix=/usr

WORKDIR /

COPY build.sh /
RUN chmod +x /build.sh

VOLUME /artifacts

ENV DEBIAN_FRONTEND newt

ENTRYPOINT ["/build.sh"]
CMD ["-o", "/artifacts"]

