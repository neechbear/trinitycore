# Getting Started

This guide will walk you through setting up a TrinityCore private WoW server for
Wrath of the Lich King (game client version 3.3.5a).


## Requirements

You will need a Linux or OS X machine that has the following things installed:

  * `make`
  * `git`
  * `jq`
  * Docker
  * `docker-compose` - Follow instructions at https://docs.docker.com/compose/install/

You will also need a *legitimate* copy of World of Warcraft: Wrath of the Lich
King (game client version 3.3.5a).


### Debian & Ubuntu

These required packages can be installed on Debian & Ubuntu by running the
following from your Linux shell:

    $ sudo apt-get install make git jq
    $ curl -sSL https://get.docker.com/ | sh


### CentOS & RedHat Enterprise Linux

These required packages can be installed on CentOS & RHEL by running the
following from your Linux shell:

    $ sudo yum install make git jq
    $ curl -sSL https://get.docker.com/ | sh


## Installation

You will need to preform 4 distinct steps in order to start your private
TrinityCore server, (and start playing on it).

  1. Download _or_ build the TrinityCore container image.

  2. Generate the map data used by the `worldserver`. This will require a copy
     of the World of Warcraft game client files.

  3. Start the TrinityCore and database containers.

  4. Configure your World of Warcraft game client, then connect to your
     TrinityCore private WoW server.


### Downloading Pre-built TrinityCore Container

From your Linux or macOS shell, run the following:

    $ docker pull nicolaw/trinitycore:3.3.5-sql

You can check how up-to-date the downloaded container image is by running the
following command:

    $ docker inspect nicolaw/trinitycore:3.3.5-sql | jq -r '.[0].Config.Labels'

If you find that it is too old and that you need a newer version, you can build
your own version of the container by following the instructions in the next step
instead.


### Building TrinityCore Cotnainer

From your Linux or macOS shell, run the following:

    $ git clone https://github.com/neechbear/trinitycore
    $ make build FLAVOUR=sql

Depending on the performance of your machine, this may take up to 1 hour to
complete.

The TrinityCore conatiner image `nicolaw/trinitycore:3.3.5-sql` should now be
built and ready to use.


### Generating Map Data

This process needs to read the data files from your copy of the World of Warcaft
game client.

You should copy your game client (usually in `C:\Program Files
(x86)\World of Warcraft\` on Windows, or `/Applications/World of Warcraft.app`
on OS X), in to a directory called `World_of_Warcraft` (using underscores
instead of spaces), under the `trinitycore` directory that you created in the
previous compile steps.

![Copying C:\Program Files (x86)\World of Warcraft\ to ~/trinitycore/World_of_Warcraft](.GettingStarted1.gif)

You can now run the next command to generate the map data.

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

You can now stop and start your TrinityCore server whenever you wish. The server
may be run permanently as a detached background service by using
`docker-compose` directly:

    $ docker-compose start


### Creating Initial GM Administrator Account

Use the `tcpassword` command to generate a new password that can be inserted
directly into the MySQL database.

    $ make run
    $ tcpassword janedoe letmein > password.sql
    $ mysql -h 127.0.0.1 -P 3306 -u trinity -p -D auth < password.sql

At present this script is a simple PHP example taken from the upstream GitHub
issue https://github.com/TrinityCore/TrinityCore/issues/25157. It will be
rewritten as a standalone binary in the near future.

In the mean time simply login with the default username `trinity` and password
`trinity`, and use the standard GM commands to create additional users. Refer to
https://trinitycore.atlassian.net/wiki/spaces/tc/pages/2130065/GM+Commands for
more details.

    .account create janedoe password
    .account set gmlevel janedoe 3 -1


### Configuring your Game Client

As with any private WoW server, you will need to edit your `realmlist.wtf` file
in your `World of Warcraft\Data\enUS\` game client directory. Simply open the
file in your favorite text editor (or Notepad), and change the logon server to
be the IP address or hostname of the Linux machine that will be running your
TrinityCore server.

You can now launch your World of Warcraft game client, and login with the
default username `trinity` and password `trinity`.

The default `trinity` account has full Game-Master (GM) permissions. See
https://trinitycore.atlassian.net/wiki/display/tc/GM+Commands for a full list of
available commands.

Enjoy!

