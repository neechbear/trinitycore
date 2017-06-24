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

# https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
# https://trinitycore.atlassian.net/wiki/display/tc/Requirements
RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Use-Pty=0 install \
    blip \
    cmake \
    g++ \
    gcc \
    git \
    jq \
    make \
    p7zip-full \
    libboost1.55-dev \
    libboost-filesystem1.55-dev \
    libboost-iostreams1.55-dev \
    libboost-program-options1.55-dev \
    libboost-regex1.55-dev \
    libboost-system1.55-dev \
    libboost-thread1.55-dev \
    libssl-dev \
    libmysqlclient-dev \
    libreadline6-dev \
    zlib1g-dev \
    libbz2-dev \
    libncurses5-dev \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /

COPY build.sh /
RUN chmod +x /build.sh

VOLUME /artifacts

ENTRYPOINT ["/build.sh"]
CMD ["-o", "/artifacts"]

