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
    nicolaw/trinitycore   3.3.5-slim   e95b78fcfe20   22 minutes ago   90.9MB
    
    $ docker run --rm -it nicolaw/trinitycore:3.3.5-slim
    / # ls -lh /opt/trinitycore/* /etc/*server.conf
    -rw-r--r--    1 root     root       13.3K Mar  9 00:44 /etc/authserver.conf
    -rw-r--r--    1 root     root      135.7K Mar  9 00:44 /etc/worldserver.conf
    
    /opt/trinitycore/bin:
    total 30M    
    -rwxr-xr-x    1 root     root        1.7M Mar  9 01:13 authserver
    -rwxr-xr-x    1 root     root      444.3K Mar  9 01:13 mapextractor
    -rwxr-xr-x    1 root     root        1.6M Mar  9 01:13 mmaps_generator
    -rwxr-xr-x    1 root     root      996.3K Mar  9 01:13 vmap4assembler
    -rwxr-xr-x    1 root     root      857.5K Mar  9 01:13 vmap4extractor
    -rwxr-xr-x    1 root     root       24.3M Mar  9 01:13 worldserver

## Building

Building the container image is optional as you can simply pull the latest
`nicolaw/trinitycore:3.3.5-slim` image directly from Docker Hub as illustrated
above. Alternatively you can compile TrinityCore inside a container to build
the container image using the `image` target:

    $ make image

Generate the map data from your game client directory in `./World_of_Warcraft`
using the `mapdata` target:

    $ make mapdata

## Running

Run the database, world server and auth server using `docker-compose`:

    $ docker-compose up

