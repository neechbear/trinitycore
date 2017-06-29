# Dockerised TrinityCore

See [GettingStarted.md](GettingStarted.md) for a guide on how to run TrinityCore
in a fully Dockerised environment.

See [docker/build/README.md](docker/build/README.md) for instructions regarding
the TrinityCore build container, (published as Docker image
`nicolaw/trinitycore` on Docker Hub at
https://hub.docker.com/r/nicolaw/trinitycore/).


## Todo

Some planned future improvements to this project are as follows:

  1. Implement additional containers for database and SmartAI editing and
     browsing.

    * https://github.com/ShinDarth/TC-JSON-API
      * https://github.com/ShinDarth/TC-JSON-API/blob/master/INSTALL.md
    * https://github.com/Helias/Keira2
    * https://github.com/Sarjuuk/aowow
    * https://github.com/neechbear/tcadmin

  2. Harmonise `docker/trinitycore/docker-compose.yaml` to read and honor
     `Makefile` settings and variables.

  3. Attempt to make Docker base container images work with Alpine, Ubuntu and
     CentOS as well as Debian Jessie.

  4. See what improvements can be incorporated from other similar projects like
     https://github.com/azerothcore/docker-files/.

  5. Add TravisCI and CodeClimate integration to the GitHub project.


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

