# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

# https://hub.docker.com/_/php/
FROM php:7.1.6-alpine
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV DB_HOST mariadb
ENV DB_PORT 3306
ENV DB_WORLD world
ENV DB_CHARACTERS characters
ENV DB_AUTH auth
ENV DB_DBC dbc
ENV DB_USERNAME trinity
ENV DB_PASSWORD trinity

ENV BIND_IP 0.0.0.0
ENV BIND_PORT 80

ENV HEALTHCHECK_URL http://localhost:80/public/index.php/gameobject/template/Milk

# Add repository and packages.
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk add --no-cache git composer jq bash

# Wait for the database server to come up first.
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh "/bin/wait-for-it.sh"
RUN chmod +x "/bin/wait-for-it.sh"

# Install TC-JSON-API software according to
# https://github.com/ShinDarth/TC-JSON-API/blob/master/INSTALL.md.
RUN composer global require "laravel/installer=~1.1"
RUN git clone https://github.com/ShinDarth/TC-JSON-API.git /usr/local/tcjsonapi
WORKDIR "/usr/local/tcjsonapi"
RUN composer install
RUN cp .env.example .env
RUN php artisan key:generate
RUN php artisan jwt:generate
RUN docker-php-ext-install pdo pdo_mysql
RUN find / -name 'pdo*.so' | xargs printf 'extension=%s\n' >> /etc/php5/php.ini
RUN php artisan migrate --force || true

CMD ["/bin/bash", "-c", "/bin/wait-for-it.sh ${DB_HOST}:${DB_PORT} -- /usr/bin/php -S ${BIND_IP}:${BIND_PORT} /usr/local/tcjsonapi/server.php"]

# https://github.com/ShinDarth/TC-JSON-API/wiki/Search-routes.
HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=30s \
  CMD curl -sSLf "${HEALTHCHECK_URL}" | jq -r '.[].name' | grep -x "Barrel of Milk" || exit 1

