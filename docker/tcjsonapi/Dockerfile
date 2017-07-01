# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

FROM ubuntu:xenial
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq -o Dpkg::Use-Pty=0 update && \
    apt-get -qq -o Dpkg::Use-Pty=0 install -y \
    curl \
    git \
    jq \
    netcat \
    php7.0 \
    php7.0-mysql \
    php-mbstring \
    php-sqlite3 \
    php-xml \
    unzip \
 < /dev/null > /dev/null \
 && rm -rf /var/lib/apt/lists/*

ENV DB_HOST mariadb
ENV DB_PORT 3306
ENV DB_USERNAME trinity
ENV DB_PASSWORD trinity
ENV DB_AUTH auth
ENV DB_CHARACTERS characters
ENV DB_WORLD world
ENV DB_DBC dbc

ENV BIND_IP 0.0.0.0
ENV BIND_PORT 80

ENV HEALTHCHECK_URL http://localhost:80/public/index.php/gameobject/template/Milk

# Wait for the database server to come up first.
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh "/bin/wait-for-it.sh"
RUN chmod +x "/bin/wait-for-it.sh"

# Install TC-JSON-API software according to
# https://github.com/ShinDarth/TC-JSON-API/blob/master/INSTALL.md.

# Install composer and laravel first.
RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer \
  && chmod +x /usr/local/bin/composer
RUN composer global require "laravel/installer=~1.1"

RUN git clone --depth 1 --single-branch https://github.com/ShinDarth/TC-JSON-API.git /usr/local/TC-JSON-API
WORKDIR "/usr/local/TC-JSON-API"

# Build the application.
RUN composer install
RUN cp .env.example .env
RUN php artisan key:generate
RUN php artisan jwt:generate
RUN php artisan migrate --force || true

CMD ["/bin/bash", "-c", "/bin/wait-for-it.sh ${DB_HOST}:${DB_PORT} --timeout=0 --strict -- /usr/bin/php -S ${BIND_IP}:${BIND_PORT} /usr/local/TC-JSON-API/server.php"]

# https://github.com/ShinDarth/TC-JSON-API/wiki/Search-routes.
HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=30s \
  CMD curl -sSLf "${HEALTHCHECK_URL}" | jq -r '.[].name' | grep -x "Barrel of Milk" || exit 1

