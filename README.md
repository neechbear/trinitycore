# Dockerised TrinityCore 3.3.5

TrinityCore build environment and wrapper.

## Overview 

Pull using `docker pull nicolaw/trinitycore-build`.

Will attempt to build and create Docker service containers for TrinityCore 3.3.5
branch (WotLK) by default. Source is pulled from
https://github.com/TrinityCore/TrinityCore, and built according to install
instructions, as documented at
https://trinitycore.atlassian.net/wiki/display/tc/Installation+Guide.

Command line help is available through --help option.

## Synopsis

    build.sh version 1.0
    (C) 2017 Nicola Worthington. : Nicola Worthington <nicolaw@tfb.net>.

    TrinityCore Dockerised build wrapper.

    Optional arguments:
     -h, --help : Boolean. Show this help.
     -o, --output=VALUE : String. Output directory for finished build artifacts.  (Default "/artifacts")
     -b, --branch=VALUE : String. Branch (version) of TrinityCore to build. (Default "3.3.5")
     -r, --repo=VALUE : String. Git repository to clone from. (Default "https://github.com/TrinityCore/TrinityCore.git")
     -t, --tdb=VALUE : String. TDB database release archive URL to download.
     -D, --define=VALUE : Array. Supply additional -D arguments to cmake. (See note)
     -d, --debug : Boolean. Produce a debug build.
     -c, --clang : Boolean. Use clang compiler instead of gcc.
     -v, --verbose : Boolean. Print more verbose debugging output.

    Note: arguments of Array & Hash types may be specified multiple times.

    See https://github.com/neechbear/trinitycore, https://neech.me.uk,
    https://github.com/neechbear/tcadmin, https://nicolaw.uk/#WoW and
    https://hub.docker.com/r/nicolaw/trinitycore-build.

## See Also

Authors related works:

* https://github.com/neechbear/trinitycore
* https://hub.docker.com/r/nicolaw/trinitycore-build
* https://github.com/neechbear/tcadmin
* https://neech.me.uk
* https://nicolaw.uk/#WoW

Related TrinityCore projects:

* https://trinitycore.atlassian.net/wiki/display/tc/Installation+Guide
  * https://github.com/TrinityCore/
    * https://github.com/TrinityCore/TrinityCore
    * https://github.com/TrinityCore/aowow
* https://github.com/Sarjuuk/aowow
  * https://db.rising-gods.de

