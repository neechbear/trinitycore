FROM debian:jessie
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Use-Pty=0 install \
    software-properties-common python-software-properties \
 < /dev/null > /dev/null

RUN add-apt-repository ppa:nicolaw/blip && \
    find /etc/apt/sources.list.d/ && \
    sed -i 's/jessie/trusty/g' /etc/apt/sources.list.d/nicolaw-blip-jessie.list

RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Use-Pty=0 install \
    blip \
    cmake \
    g++ \
    gcc \
    git \
    jq \
    libboost-dev \
    libboost-thread-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libbz2-dev \
    libmysqlclient-dev \
    libncurses-dev \
    libreadline-dev \
    libssl-dev \
    make \
    p7zip \
    zlib1g-dev \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /trinitycore

ADD trinitycore /trinitycore
COPY build.sh /

VOLUME /artifacts

CMD ["/bin/bash", "/build.sh"]

