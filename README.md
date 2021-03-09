# trinitycore

This slim container image for TrinityCore 3.3.5 is a work in progress. See
`Dockerfile` and `Makefile` for a list of to-do tasks.

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

