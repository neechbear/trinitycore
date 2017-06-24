# Dockerised TrinityCore 3.3.5

TrinityCore build environment and wrapper.

## Overview 

Pull using `docker pull nicolaw/trinitycore`.

Will attempt to build and create Docker service containers for TrinityCore 3.3.5
branch (WotLK) by default. Source is pulled from
https://github.com/TrinityCore/TrinityCore, and built according to install
instructions, as documented at
https://trinitycore.atlassian.net/wiki/display/tc/Installation+Guide.

Command line help is available through --help option.

    $ docker pull nicolaw/trinitycore
    $ mkdir artifacts
    $ docker run -it --rm -v "$PWD/artifacts":/artifacts nicolaw/trinitycore

YouTube video demonstration for beginners can be viewed at
https://www.youtube.com/watch?v=bd7xFsGoAEk.

## Synopsis

    $ docker run --rm trinitycore/build --help
    build.sh version 1.0
    (C) 2017 Nicola Worthington. : Nicola Worthington <nicolaw@tfb.net>.

    TrinityCore Dockerised build wrapper.

    Optional arguments:
     -h, --help : Boolean. Show this help.
     -o, --output=VALUE : String. Output directory for finished build artifacts. (Default "/artifacts")
     -b, --branch=VALUE : String. Branch (version) of TrinityCore to build. (Default "3.3.5")
     -t, --tdb=VALUE : String. TDB database release archive URL to download.
     -r, --repo=VALUE : String. Git repository to clone from. (Default "https://github.com/TrinityCore/TrinityCore.git")
     -R, --reference=VALUE : String. Reference Git repository on local machine.
     -D, --define=VALUE : Array. Supply additional -D arguments to cmake. (See note)
     -d, --debug : Boolean. Produce a debug build.
     -s, --shell : Boolean. Drop to a command line shell on errors.
     -c, --clang : Boolean. Use clang compiler instead of gcc.
     -v, --verbose : Boolean. Print more verbose debugging output.

    Note: arguments of Array & Hash types may be specified multiple times.

    See https://github.com/neechbear/trinitycore, https://neech.me.uk,
    https://github.com/neechbear/tcadmin, https://nicolaw.uk/#WoW and
    https://hub.docker.com/r/nicolaw/trinitycore.

## Caching & Debugging

If you are experiencing build failures or wish to preform repeated build
attempts to debug a problem, you may wish to use the `--shell`, `--reference`
and `--tdb` options.

    # Pre-download TrinityCore Git repository and database archive.
    $ git clone --bare https://github.com/TrinityCore/TrinityCore.git trinitycore-cache
    $ curl -L -o trinitycore-cache/TDB_full_335.63_2017_04_18.7z \
        https://github.com/TrinityCore/TrinityCore/releases/download/TDB335.63/TDB_full_335.63_2017_04_18.7z

    # Pull and run the Docker build container, using pre-downloaded sources.
    $ docker pull nicolaw/trinitycore
    $ mkdir artifacts
    $ docker run -it -v "$PWD/artifacts":/artifacts \
                     -v "$PWD/trinitycore-cache":/reference \
                     nicolaw/trinitycore \
                     --shell --verbose --reference=/reference \
                     --tdb file:///reference/TDB_full_335.63_2017_04_18.7z \

Here you are pre-downloading both the TrinityCore database archive files, and
Git repository. The `--shell` option will drop you to a Bash shell prompt if the
build fails if you interrupt the build script by pressing Control-C.

## See Also

Authors related works:

* https://github.com/neechbear/trinitycore
* https://hub.docker.com/r/nicolaw/trinitycore
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
