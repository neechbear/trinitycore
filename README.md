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
    $ docker run -it --rm -v "$PWD/$artifacts":/artifacts trinitycore/build

## Synopsis

    $ docker run --rm trinitycore/build --help
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
    https://hub.docker.com/r/nicolaw/trinitycore.

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
