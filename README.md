# TrinityCore

* [Docker Hub container image](https://hub.docker.com/r/nicolaw/trinitycore/)
* [GitHub source repository](https://github.com/NeechBear/trinitycore/)
* [Dockerfile](https://raw.githubusercontent.com/neechbear/trinitycore/master/Dockerfile)
* [docker-compose.yaml](https://raw.githubusercontent.com/neechbear/trinitycore/master/docker-compose.yaml)
* See [GettingStarted.md](https://github.com/neechbear/trinitycore/blob/master/GettingStarted.md)
  for a guide on how to run TrinityCore in Docker using this container image.

This slim container image for TrinityCore 3.3.5.

    $ docker pull nicolaw/trinitycore:3.3.5-slim
    
    $ docker image list nicolaw/trinitycore
    REPOSITORY            TAG          IMAGE ID       CREATED        SIZE
    nicolaw/trinitycore   3.3.5-sql    3e3597c6139d   3 hours ago    603MB
    nicolaw/trinitycore   3.3.5-slim   2001f02d57f7   3 hours ago    98MB
    nicolaw/trinitycore   3.3.5-full   b30da33946f4   14 hours ago   714MB
    
    $ docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels'
    
    $ docker run --rm -it nicolaw/trinitycore:3.3.5-slim sh -c "ls -lh /opt/trinitycore/* /etc/*server.conf* /usr/local/bin"
    -rw-r--r--    1 root     root       13.3K Mar 11 23:50 /etc/authserver.conf.dist
    -rw-r--r--    1 root     root      135.7K Mar 11 23:50 /etc/worldserver.conf.dist
    
    /opt/trinitycore/bin:
    total 30M    
    -rwxr-xr-x    1 root     root        1.7M Mar 12 12:38 authserver
    -rwxr-xr-x    1 root     root      444.3K Mar 12 12:38 mapextractor
    -rwxr-xr-x    1 root     root        1.6M Mar 12 12:38 mmaps_generator
    -rwxr-xr-x    1 root     root      996.3K Mar 12 12:38 vmap4assembler
    -rwxr-xr-x    1 root     root      857.5K Mar 12 12:38 vmap4extractor
    -rwxr-xr-x    1 root     root       24.3M Mar 12 12:38 worldserver
    
    /usr/local/bin:
    total 36K    
    -rwxrwxr-x    1 root     root         537 Mar 11 23:46 gettdb
    -rwx--x--x    1 root     root       24.0K Jan  1  1970 tcadmin
    -rwxrwxr-x    1 root     root         905 Mar 11 23:46 tcpassword
    -rwx--x--x    1 root     root        3.6K Jan  1  1970 wait-for-it.sh

    # Extract map data.
    $ docker run --rm -it -v $PWD/World_of_Warcraft:/wow -v $PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-sql mapextractor -i /wow -o /mapdata -e 7 -f 0
    $ docker run --rm -it -v $PWD/World_of_Warcraft:/wow -v $PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-sql vmap4extractor -l -d /wow/Data
    $ docker run --rm -it -v $PWD/World_of_Warcraft:/wow -v $PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-sql vmap4assembler /mapdata/Buildings /mapdata/vmaps
    $ docker run --rm -it -v $PWD/World_of_Warcraft:/wow -v $PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-sql mmaps_generator
    
    # Run authserver and worldserver in the background.
    $ docker run --rm -p 3724:3724 -v $PWD/authserver.conf:/etc/authserver.conf -d nicolaw/trinitycore:3.3.5-sql authserver
    $ docker run --rm -p 8085:8085 -p 3443:3443 -p 7878:7878 -v $PWD/worldserver.conf:/etc/worldserver.conf -v $PWD/mapdata:/mapdata -d nicolaw/trinitycore:3.3.5-sql worldserver


## Building

Building the container image is optional as you can simply pull the latest
`nicolaw/trinitycore:3.3.5-slim` image directly from Docker Hub as illustrated
above.

Alternatively you can compile TrinityCore inside a container to build the
container image directly with `docker` or using the convenience Makefile wrapper
using the `image` target:

    # Building manually with Docker
    $ docker build -f Dockerfie . --build-arg FLAVOUR=slim
    
    # Convenience Makefile wrapper
    $ make build

Three different image types can be created by specifying the `FLAVOUR` variable
with the `image` target. If you only need to TrinityCore binaries (`authserver`,
`worldserver` and the map data extraction tools), then the `slim` flavour should
be sufficient. Most people will probably want to use the `sql` flavour as it
also includes all the SQL files needed to bootstrap all the databases needed by
the `authserver` and `worldserver`.

    $ make build FLAVOUR=slim # minimal image size without SQL files
    $ make build FLAVOUR=sql  # includes all SQL files needed to populate the DB
    $ make build FLAVOUR=full # includes all SQL, source files and build root


### Generating Map Data

The most convenient way to generate the map data from your game client directory
in `./World_of_Warcraft/` is to use the `mapdata` target:

    $ make mapdata

Alternatively you can manually execute the commands documented in the container
image labels, which can be displayed using the following command:

    $ docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels'

You can either copy and paste those commands from the prined output, or run
them directly like so:

    $ eval $(docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.mapextractor"')
    $ eval $(docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.vmap4extractor"')
    $ eval $(docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.vmap4assembler"')
    $ eval $(docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.mmaps_generator"')


## Running

Run the database, world server and auth server using `docker-compose`:

    $ docker-compose up

Refer to the Docker Compose documentation at https://docs.docker.com/compose for
more information.

The container image includes helpful labels that suggest various commands for
common usage patterns:

    $ docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels'
    {
      "author": "Nicola Worthington <nicolaw@tfb.net>",
      "org.label-schema.build-date": "2021-03-10 19:58:07+00:00",
      "org.label-schema.description": "TrinityCore MMO Framework",
      "org.label-schema.docker.cmd.authserver": "docker run --rm -p 3724:3724 -v $PWD/authserver.conf:/etc/authserver.conf -d nicolaw/trinitycore:3.3.5-slim authserver",
      "org.label-schema.docker.cmd.mapextractor": "docker run --rm -v $PWD/World_of_Warcraft:/wow -v $PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-slim mapextractor -i /wow -o /mapdata -e 7 -f 0",
      "org.label-schema.docker.cmd.mmaps_generator": "docker run --rm -v $PWD/World_of_Warcraft:/wow -v $PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-slim mmaps_generator",
      "org.label-schema.docker.cmd.vmap4assembler": "docker run --rm -v $PWD/World_of_Warcraft:/wow -v $PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-slim vmap4assembler /mapdata/Buildings /mapdata/vmaps",
      "org.label-schema.docker.cmd.vmap4extractor": "docker run --rm -v $PWD/World_of_Warcraft:/wow -v $PWD/mapdata:/mapdata -w /mapdata -it nicolaw/trinitycore:3.3.5-slim vmap4extractor -l -d /wow/Data",
      "org.label-schema.docker.cmd.worldserver": "docker run --rm -p 8085:8085 -p 3443:3443 -p 7878:7878 -v $PWD/worldserver.conf:/etc/worldserver.conf -v $PWD/mapdata:/mapdata -d nicolaw/trinitycore:3.3.5-slim worldserver",
      "org.label-schema.name": "nicolaw/trinitycore",
      "org.label-schema.schema-version": "1.0",
      "org.label-schema.url": "https://nicolaw.uk/trinitycore/",
      "org.label-schema.usage": "https://github.com/neechbear/trinitycore/blob/master/README.md",
      "org.label-schema.vcs-ref": "e79ce53118c0c2c510063ab94c02d4f6b7f24912",
      "org.label-schema.vcs-url": "https://github.com/NeechBear/trinitycore",
      "org.label-schema.vendor": "Nicola Worthington",
      "org.label-schema.version": "3.3.5-nicolaw2.0"
    }

For example, the following gives a starting command suggestion for how to run
the world server:

    $ docker inspect nicolaw/trinitycore:3.3.5-slim | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.worldserver"'
    docker run --rm -p 8085:8085 -p 3443:3443 -p 7878:7878 -v $PWD/worldserver.conf:/etc/worldserver.conf -v $PWD/mapdata:/mapdata -d nicolaw/trinitycore:3.3.5-sql worldserver


## Customisation

Edit the `authserver.conf` and `worldserver.conf` files, and SQL files used to
populate the database in the `sql/` directory.

See https://trinitycore.atlassian.net/wiki/spaces/tc/overview for more
information.


## Downloading Database SQL

If you use the `sql` flavour image (`nicolaw/trinitycore:3.3.5-sql`) then you
will already have everything you need to run your TrinityCore server, including
populating and your database from scratch.

    $ docker run --rm -it nicolaw/trinitycore:3.3.5-sql
    / # ls -lh /*sql* /src/*
    lrwxrwxrwx    1 root     root          47 Mar 12 12:40 /TDB_full_world_335.21021_2021_02_15.sql -> src/sql/TDB_full_world_335.21021_2021_02_15.sql
    lrwxrwxrwx    1 root     root           7 Mar 12 12:40 /sql -> src/sql
    
    /src/sql:
    total 255M   
    -rw-r--r--    1 root     root      255.2M Feb 15 12:37 TDB_full_world_335.21021_2021_02_15.sql
    drwxr-xr-x    3 root     root        4.0K Mar 11 23:50 base
    drwxr-xr-x    2 root     root        4.0K Mar 11 23:50 create
    drwxr-xr-x    5 root     root        4.0K Mar 11 23:50 custom
    drwxr-xr-x    9 root     root        4.0K Mar 11 23:50 old
    drwxr-xr-x    5 root     root        4.0K Mar 11 23:50 updates

However the `sql` flavour image is considerably larger than the `slim` image. If
you use the smaller image and still need to download the SQL data, you can either
use the `gettdb` helper script, or run the `tdb` and `sql` Makefile targets:

    $ ./gettdb
    $ make tdb sql


## License

MIT License

Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

