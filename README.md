# TrinityCore

* [Docker Hub container image](https://hub.docker.com/r/nicolaw/trinitycore/)
* [GitHub source repository](https://github.com/NeechBear/trinitycore/tree/2021rewrite)
* [Dockerfile](https://raw.githubusercontent.com/neechbear/trinitycore/2021rewrite/Dockerfile)
* [docker-compose.yaml](https://raw.githubusercontent.com/neechbear/trinitycore/2021rewrite/docker-compose.yaml)

This slim container image for TrinityCore 3.3.5 is a work in progress. See the
`Dockerfile` and `Makefile` in the GitHub source repository for a list of to-do
tasks.

    $ docker pull nicolaw/trinitycore:3.3.5-slim
    
    $ docker image list nicolaw/trinitycore
    REPOSITORY            TAG          IMAGE ID       CREATED          SIZE
    nicolaw/trinitycore   3.3.5-full   135e8b4d08bf   8 seconds ago    711MB
    nicolaw/trinitycore   3.3.5-sql    9d9420b27913   8 minutes ago    595MB
    nicolaw/trinitycore   3.3.5-slim   5fdbb27d5789   16 minutes ago   90.9MB
    
    $ docker run --rm -it nicolaw/trinitycore:3.3.5-slim
    / # ls -lh /opt/trinitycore/* /etc/*server.conf*
    -rw-r--r--    1 root     root       13.3K Mar  9 00:44 /etc/authserver.conf.dist
    -rw-r--r--    1 root     root      135.7K Mar  9 00:44 /etc/worldserver.conf.dist
    
    /opt/trinitycore/bin:
    total 30M    
    -rwxr-xr-x    1 root     root        1.7M Mar  9 01:13 authserver
    -rwxr-xr-x    1 root     root      444.3K Mar  9 01:13 mapextractor
    -rwxr-xr-x    1 root     root        1.6M Mar  9 01:13 mmaps_generator
    -rwxr-xr-x    1 root     root      996.3K Mar  9 01:13 vmap4assembler
    -rwxr-xr-x    1 root     root      857.5K Mar  9 01:13 vmap4extractor
    -rwxr-xr-x    1 root     root       24.3M Mar  9 01:13 worldserver
    
    $ docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels'


## Building

Building the container image is optional as you can simply pull the latest
`nicolaw/trinitycore:3.3.5-slim` image directly from Docker Hub as illustrated
above. Alternatively you can compile TrinityCore inside a container to build
the container image using the `image` target:

    $ make image

Three different image types can be created by specifying the `FLAVOUR` variable
with the `image` target:

    $ make image FLAVOUR=slim # this is the default flavour if not specified
    $ make image FLAVOUR=sql  # includes all SQL files needed to populate the DB
    $ make image FLAVOUR=full # includes all SQL, source files and build root

Generate the map data from your game client directory in `./World_of_Warcraft`
using the `mapdata` target:

    $ make mapdata


## Running

Run the database, world server and auth server using `docker-compose`:

    $ docker-compose up

Refer to the Docker Compose documentation at https://docs.docker.com/compose for
more information.


## Customisation

Edit the `authserver.conf` and `worldserver.conf` files, and SQL files used to
populate the database in the `sql/` directory.

See https://trinitycore.atlassian.net/wiki/spaces/tc/overview for more
information.

