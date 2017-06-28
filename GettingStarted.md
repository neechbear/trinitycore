# Getting Started

First watch this video demonstration
https://www.youtube.com/watch?v=JmzZdexSYaM.

This guide will walk you through setting up a TrinityCore private WoW server for
Wrath of the Lich King (game client version 3.3.5a).

The default username and password will be: `trinity`.


## Requirements

You will need a Linux or OS X machine that has the following things installed:

  * `make`
  * `git`
  * Docker
  * `docker-compose` - See https://docs.docker.com/compose/install/

You will also need a *legitimate* copy of World of Warcraft: Wrath of the Lich
King (game client version 3.3.5a).


## Installation

You will need to preform 4 distinct steps in order to start your private
TrinityCore server, (and start playing on it).

  1. Compile the TrinityCore server.

  2. Generate the map data used by the `worldserver`. This will require a copy
     of the World of Warcraft game client files.

  3. Start the TrinityCore server.

  4. Configure your World of Warcraft game client, then connect to your
     TrinityCore private WoW server.


### Compiling TrinityCore

From your Linux shell, run the following:

    $ git clone https://github.com/neechbear/trinitycore
    $ cd trinitycore
    $ make build

Depending on the performance of your machine, this may take up to 1 hour to
complete.

The TrinityCore server should now be compiled inside of a Docker container. The
resulting build artifacts will be placed in to the `./artifacts/` sub-directory
in your current path.


### Generating Map Data

This process needs to read the data files from your copy of the World of Warcaft
game client.

You should copy your game client (usually in `C:\Program Files
(x86)\World of Warcraft\` on Windows, or `/Applications/World of Warcraft.app`
on OS X), in to a directory called `World_of_Warcraft` (using underscores
instead of spaces), under the `trinitycore` directory that you created in the
previous compile steps.

You can then run the next command to generate the map data.

    $ make mapdata

Depending on the performance of your machine, this may take up to 4 hours to
complete.


### Starting the TrinityCore Server

You are now ready to start your TrinityCore server.

The first time you start your server, it will create and import data in to the
MariaDB database. This may take a couple of minutes.

To start the server, simply run the following:

    $ make run

To stop the server, press `Control-C`.

You can now stop and start your TrinityCore server whenever you wish.


### Configuring your Game Client

As with any private WoW server, you will need to edit your `realmlist.wtf` file
in your `World of Warcraft\Data\enUS\` game client directory. Simply open the
file in your favorite text editor (or Notepad), and change the logon server to
be the IP address or hostname of the Linux machine that will be running your
TrinityCore server.

You can then launch your World of Warcraft game client, and login with the
default username `trinity` and password `trinity`.

The default `trinity` account has full Game-Master (GM) permissions. See
https://trinitycore.atlassian.net/wiki/display/tc/GM+Commands for a full list of
available commands.

Enjoy!


## See Also

Related works by the same author:

  * https://github.com/neechbear/trinitycore
  * https://hub.docker.com/r/nicolaw/trinitycore
  * https://github.com/neechbear/tcadmin
  * https://neech.me.uk
  * https://nicolaw.uk/#WoW

Related TrinityCore projects and links:

  * https://trinitycore.atlassian.net/wiki/display/tc/GM+Commands
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

