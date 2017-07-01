# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

#
# TODO: This Dockerfile is currently VERY INCOMPLETE!
#

FROM ubuntu:xenial
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq -o Dpkg::Use-Pty=0 update && \
    apt-get -qq -o Dpkg::Use-Pty=0 install -y \
    curl \
    git \
    jq \
    mysql-client \
    netcat \
    php7.0 \
    php7.0-mysql \
    php-gd \
    php-mbstring \
    php-xml \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

ENV DB_HOST mariadb
ENV DB_PORT 3306
ENV DB_USERNAME trinity
ENV DB_PASSWORD trinity
ENV DB_AOWOW aowow

ENV BIND_IP 0.0.0.0
ENV BIND_PORT 80

ENV HEALTHCHECK_URL http://localhost:80/

# Wait for the database server to come up first.
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh "/bin/wait-for-it.sh"
RUN chmod +x "/bin/wait-for-it.sh"

# Install aowow according to the README.md instructions found at
# https://github.com/Sarjuuk/aowow/blob/master/README.md.

# Install composer and laravel first.
RUN git clone --depth 1 --single-branch https://github.com/Sarjuuk/aowow.git /usr/local/aowow
RUN git clone --depth 1 --single-branch https://github.com/Kanma/MPQExtractor.git /usr/local/MPQExtractor
WORKDIR "/usr/local/aowow"
COPY config.php "/usr/local/aowow/config/config.php"

CMD ["/bin/bash", "-c", "/bin/wait-for-it.sh ${DB_HOST}:${DB_PORT} -- /usr/bin/php -S ${BIND_IP}:${BIND_PORT} /usr/local/aowow/index.php"]

# https://github.com/ShinDarth/TC-JSON-API/wiki/Search-routes.
HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=30s \
  CMD curl -sSLf "${HEALTHCHECK_URL}" || exit 1

