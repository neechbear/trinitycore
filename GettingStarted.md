# Getting Started

First watch this video demonstration
https://www.youtube.com/watch?v=JmzZdexSYaM.

The default username and password is: `trinity`.


## Requirements

You will need a Linux machine that has the following things installed:

  * make
  * git
  * Docker
  * docker-compose


## Installation

You will need to preform 3 distinct steps in order to start your private
TrinityCore server, (and start playing on it).

  1. Compile the TrinityCore server.

  2. Generate the map data used by the `worldserver`. This will require a copy
     of the World of Warcraft game client files.

  3. Start the TrinityCore server, and connect to it using your World of
     Warcraft game client.


### Compiling TrinityCore

From your Linux shell, run the following:

    $ git clone https://github.com/neechbear/trinitycore
    $ cd trinitycore
    $ make build

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


### Starting the TrinityCore Server

You are now ready to start your TrinityCore server.

The first time you start your server, it will create and import data in to the
MariaDB database. This may take a couple of minutes.

To start the server, simply run the following:

    $ make run

To stop the server, press `Control-C`.

As with any private WoW server, you will need to edit your `realmlist.wtf` file
in your `World of Warcraft\Data\enUS\` game client directory. Simply open the
file in your favorite text editor (or Notepad), and change logon server to be
the IP address or hostname of the Linux machine that will be running your
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

* https://trinitycore.atlassian.net/wiki/display/tc/Installation+Guide
  * https://github.com/TrinityCore/
    * https://github.com/TrinityCore/TrinityCore
    * https://github.com/TrinityCore/aowow
* https://github.com/Sarjuuk/aowow
  * https://db.rising-gods.de


## License

MIT License

Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

