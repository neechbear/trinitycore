# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

# https://hub.docker.com/_/httpd/
FROM httpd:alpine
LABEL author="Nicola Worthington <nicolaw@tfb.net>"

ENV TC_JSON_API_URL http://tcjsonapi:80/public/index.php/"
ENV HEALTHCHECK_URL http://localhost:80/Keira2/

# Add packages.
RUN apk add --no-cache git

# Install Keira2 according to https://github.com/Helias/Keira2.
RUN git clone --depth 1 --single-branch  https://github.com/Helias/Keira2.git /usr/local/apache2/htdocs/Keira2
RUN sed -r -e 's@^(\s*app\.defaultAPI\s*=\s*).+;@\1'"${TC_JSON_API_URL}"';@g;' \
  < /usr/local/apache2/htdocs/Keira2/config.js.dist \
  > /usr/local/apache2/htdocs/Keira2/config.js
COPY htaccess "/usr/local/apache2/htdocs/.htaccess"

HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=30s \
  CMD curl -sSLf "${HEALTHCHECK_URL}" || exit 1

