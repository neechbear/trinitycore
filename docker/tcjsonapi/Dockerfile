# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

# https://hub.docker.com/_/php/
FROM php:latest
LABEL author="Nicola Worthington <nicolaw@tfb.net>"



# Wait for the database server to come up first.
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh "${install_prefix}/bin/wait-for-it.sh"

# Add worldserver binary and wrapper, and make executable.
COPY worldserver.sh "${install_prefix}/bin/worldserver.sh"
COPY worldserver "${install_prefix}/bin/worldserver"
RUN chmod +x "${install_prefix}/bin"/*

# Add TDB_*.sql database dump for initial world database initialisation.
ADD TDB_*.sql "${install_prefix}/bin/"

ENTRYPOINT ["./worldserver.sh"]

