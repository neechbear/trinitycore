FROM ubuntu:16.04
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Use-Pty=0 install \
    cmake \
    g++ \
    gcc \
    git \
    libboost-all-dev \
    libbz2-dev \
    libmysqlclient-dev \
    libncurses-dev \
    libreadline-dev \
    libssl-dev \
    make \
    p7zip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /trinitycore

ADD trinitycore /trinitycore
COPY build.sh /

VOLUME /artifacts

CMD ["/build.sh"]

