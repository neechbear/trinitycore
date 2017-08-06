# MIT License
# # Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

# Default username and password to create a GM user.
DEFAULT_GM_USER = trinity
DEFAULT_GM_PASSWORD = trinity
DEFAULT_GM_ID = 1

# Database hostname and port. Defaulted to Docker swarm container mariadb.
DB_HOST = mariadb
DB_PORT = 3306
DB_USERNAME = trinity
DB_PASSWORD = trinity
DB_WORLD = world
DB_CHARACTERS = characters
DB_AUTH = auth

# What realm ID and port should the worldserver identify itself as.
WORLDSERVER_REALM_ID = 2
WORLDSERVER_PORT = 8085
WORLDSERVER_NAME = "TrinityCore"

# Enable worldserver remote access and SOAP API by default.
WORLDSERVER_RA = 1
WORLDSERVER_RA_IP = 0.0.0.0
WORLDSERVER_SOAP = 1
WORLDSERVER_SOAP_IP = 0.0.0.0

# Location of WoW game client files, used to generate worldserver map data.
GAME_CLIENT = World_of_Warcraft

# Package type to build for map data. (Optional step).
PKG_TYPE = deb

# Build artifacts output path.
ARTIFACTS = artifacts
SQL_ARTIFACTS = $(ARTIFACTS)/sql
SQL_INITDB_ARTIFACTS = $(ARTIFACTS)/docker-entrypoint-initdb.d

# See https://hub.docker.com/_/mariadb/: Initializing a fresh instance.
SQL_IMPORT = $(addprefix $(SQL_INITDB_ARTIFACTS)/, 001-permissions.sql \
	002-tc-json-api-dbc.sql 003-tc-json-api-dbc-achievements.sql \
	004-aowow.sql 005-aowow-db-structures.sql)

# Custom auth SQL, fixup realmlist, add GM user.
SQL_FIX_REALMLIST = $(SQL_ARTIFACTS)/custom/auth/fix_realmlist.sql
SQL_ADD_GM_USER = $(SQL_ARTIFACTS)/custom/auth/add_gm_user.sql

# TDB database files used by worldserver to initialise the world database.
SQL_TDB = $(notdir $(wildcard $(SQL_ARTIFACTS)/TDB_*/*.sql))
SQL_TDB_WORLDSERVER = $(addprefix docker/worldserver/, $(SQL_TDB))

# Version of TrinityCore we are compiling, packaging and running.
# (We currently only work with 3.3.5 branch, so this is a partially moot).
BRANCH := $(shell cat $(ARTIFACTS)/branch 2>/dev/null)
BRANCH := $(if $(BRANCH),$(BRANCH),3.3.5)
SHORT_HASH := $(shell cat $(ARTIFACTS)/git-rev-short 2>/dev/null)

# Directories expected to be generated for worldserver map data.
MAP_DATA_DIR = mapdata
MAP_DATA_ARTIFACTS = $(ARTIFACTS)/$(MAP_DATA_DIR)
MAP_DATA = $(addprefix $(MAP_DATA_ARTIFACTS)/, Buildings Cameras dbc maps mmaps vmaps)
MAP_DATA_DEB = $(ARTIFACTS)/trinitycore-mapdata_$(BRANCH)-$(SHORT_HASH)_all.deb
MAP_DATA_RPM = $(ARTIFACTS)/trinitycore-mapdata-$(BRANCH)-$(SHORT_HASH).noarch.rpm

# Directories expected to be generated for aowow MPQ data.
MPQ_DATA_DIR = mpqdata
MPQ_DATA_ARTIFACTS = $(ARTIFACTS)/$(MPQ_DATA_DIR)

# MPQ game data files use to generate the worldserver map data.
MPQ = $(addprefix $(GAME_CLIENT)/Data/, $(addsuffix .MPQ, \
	common expansion patch-3 patch-2 patch common-2 lichking \
	enUS/lichking-speech-enUS enUS/expansion-speech-enUS enUS/lichking-locale-enUS \
	enUS/expansion-locale-enUS enUS/base-enUS enUS/patch-enUS-2 enUS/backup-enUS \
	enUS/speech-enUS enUS/patch-enUS-3 enUS/patch-enUS enUS/locale-enUS ) )

# TrinityCore binary and config files.
TOOLS = mapextractor mmaps_generator vmap4assembler vmap4extractor
BINARIES = $(addprefix $(ARTIFACTS)/bin/, $(TOOLS) authserver worldserver)
CONF = $(addprefix $(ARTIFACTS)/etc/, authserver.conf worldserver.conf)
DIST_CONF = $(addsuffix .dist, $(CONF))

# Docker volume locations to store MariaDB databases and downloaded source.
SOURCE_DIR = source
MYSQL_DIR = mysql
MYSQL_ARTIFACTS = $(ARTIFACTS)/$(MYSQL_DIR)

# Installation location of TrinityCore server.
INSTALL_PREFIX = /opt/trinitycore


.PHONY: run build springclean clean help mapdata_deb mapdata_rpm mapdata
.INTERMEDIATE: $(addprefix docker/tools/, $(TOOLS)) $(MPQ)
.DEFAULT_GOAL := help


#
# Phony targets.
#

help:
	@echo ""
	@echo "Use 'make build' to build the TrinityCore server binaries."
	@echo "Use 'make mapdata' to generate worldserver map data from the WoW game client."
	@echo "Use 'make run' to launch the TrinityCore servers inside a Docker swarm."
	@echo "Use 'make mapdata_deb' to build a DEB package containing the worldserver map data files."
	@echo "Use 'make mapdata_rpm' to build an RPM package containing the worldserver map data files."
	@echo "Use 'make clean' to destroy ALL build artifacts from the above steps."
	@echo "Use 'make springclean' to destroy the MariaDB and configuration files."
	@echo ""
	@echo "Refer to https://github.com/neechbear/trinitycore/blob/master/GettingStarted.md for additional help."
	@echo ""

# Download and compile TrinityCore inside a Docker container.
build: $(BINARIES) $(DIST_CONF) $(SQL_ARTIFACTS)

# Generate worldserver map data from World of Warcraft game client data inside a
# Docker container.
mapdata: $(MAP_DATA)

# Run the TrinityCore server inside Docker swarm containers.
run: $(BINARIES) $(CONF) $(MAP_DATA) \
		$(SQL_FIX_REALMLIST) $(SQL_ADD_GM_USER) $(SQL_IMPORT) $(SQL_TDB_WORLDSERVER) \
		docker/worldserver/worldserver docker/authserver/authserver
	mkdir -p $(MYSQL_ARTIFACTS)
	cd docker && docker-compose up --build

# Clean ALL artifacts, source and MariaDB / mysql database files.
clean:
	@while [ -z "$$CONFIRM_CLEAN" ]; do \
			read -r -p "Are you sure you want to delete ALL build artifacts and map data? [y/N]: " CONFIRM_CLEAN; \
		done; [ "$$CONFIRM_CLEAN" = "y" ]
	rm -Rf $(ARTIFACTS) $(SOURCE_DIR)

# Clean most things, except $(ARTIFACTS) which takes a long time to build.
springclean:
	@while [ -z "$$CONFIRM_CLEAN" ]; do \
			read -r -p "Are you sure you want to delete databases and configuration? [y/N]: " CONFIRM_CLEAN; \
		done; [ "$$CONFIRM_CLEAN" = "y" ]
	rm -Rf $(MYSQL_ARTIFACTS) $(CONF) docker/worldserver/*.sql \
		docker/worldserver/worldserver docker/authserver/authserver \
		$(SQL_FIX_REALMLIST) $(SQL_ADD_GM_USER) $(SQL_INITDB_ARTIFACTS) \
		$(addprefix docker/tools/, $(TOOLS))

# DEB and RPM packaging up of mapdata files for later easier re-installation.
mapdata_deb: PKG_TYPE=deb
mapdata_deb: $(MAP_DATA_DEB)

mapdata_rpm: PKG_TYPE=rpm
mapdata_rpm: $(MAP_DATA_RPM)


#
# Real targets.
#

# Build TrinityCore server inside a Docker container.
$(BINARIES) $(DIST_CONF) $(SQL_ARTIFACTS)/create/%:
	mkdir -p $(ARTIFACTS) $(SOURCE_DIR)
	docker build -t "tcbuild" docker/build
	docker run -it --rm \
		-v "${CURDIR}/$(ARTIFACTS)":/$(ARTIFACTS) \
		-v "${CURDIR}/$(SOURCE_DIR)":/usr/local/src \
		"tcbuild" \
		--branch "$(BRANCH)" \
		--define "CMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX)" \
		--verbose

# Generate worldserver map data from World of Warcraft game client data inside a
# Docker container.
$(MAP_DATA): $(addprefix docker/tools/, $(TOOLS)) $(MPQ)
	mkdir -p $(MAP_DATA_ARTIFACTS)
	docker build -t tctools docker/tools
	docker run -it --rm \
		-v "${CURDIR}/World_of_Warcraft":/World_of_Warcraft:ro \
		-v "${CURDIR}/$(MAP_DATA_ARTIFACTS)":/$(ARTIFACTS) \
		"tctools" \
		--verbose

# Explicitly remind the user where to copy their World of Warcraft game client
# files if they are missing.
%.MPQ:
	$(error Missing $@ necessary to generate worldserver map data; please copy \
		your World of Warcraft game client in to the $(GAME_CLIENT) directory)

# Create aowow MPQ data artifact directory.
$(MPQ_DATA_ARTIFACTS):
	mkdir -p "$@"

# Create authserver and worldserver configuration files from their default
# .conf.dist artifacts.
$(CONF): $(DIST_CONF)
	sed \
			-e 's!127.0.0.1;3306;trinity;trinity;auth!$(DB_HOST);$(DB_PORT);$(DB_USERNAME);$(DB_PASSWORD);$(DB_AUTH)!g;' \
			-e 's!127.0.0.1;3306;trinity;trinity;characters!$(DB_HOST);$(DB_PORT);$(DB_USERNAME);$(DB_PASSWORD);$(DB_CHARACTERS)!g;' \
			-e 's!127.0.0.1;3306;trinity;trinity;world!$(DB_HOST);$(DB_PORT);$(DB_USERNAME);$(DB_PASSWORD);$(DB_WORLD)!g;' \
		  -e 's!^RealmID\s*=.*!RealmID = $(WORLDSERVER_REALM_ID)!g;' \
		  -e 's!^DataDir\s*=.*!DataDir = "$(INSTALL_PREFIX)/$(MAP_DATA_DIR)"!g;' \
			-e 's!^SourceDirectory\s*=.*!SourceDirectory = "$(INSTALL_PREFIX)"!g;' \
			-e 's!^BuildDirectory\s*=.*!BuildDirectory = "$(INSTALL_PREFIX)/$(SOURCE_DIR)/TrinityCore/build"!g;' \
			-e 's!^Ra\.Enable\s*=.*!Ra.Enable = $(WORLDSERVER_RA)!g;' \
			-e 's!^Ra\.IP\s*=.*!Ra.IP = "$(WORLDSERVER_RA_IP)"!g;' \
			-e 's!^SOAP\.Enabled\s*=.*!SOAP.Enabled = $(WORLDSERVER_SOAP)!g;' \
			-e 's!^SOAP\.IP\s*=.*!SOAP.IP = "$(WORLDSERVER_SOAP_IP)"!g;' \
			< "$@.dist" > "$@"

# Copy the TDB TrinityCore inintal full world database SQL import files in to
# the worldserver Docker container build directory so it can be imported on the
# first fun.
$(SQL_TDB_WORLDSERVER):
	cp -r $(SQL_ARTIFACTS)/TDB_*/"$(notdir $@)" docker/worldserver

$(SQL_INITDB_ARTIFACTS):
	mkdir -p "$@"

# Modify create_mysql.sql to grant permissions to % instead of just localhost.
# (This is nececcary when running the database server in a different Docker
# container to the authserver and worldserver).
$(SQL_INITDB_ARTIFACTS)/001-permissions.sql: $(SQL_INITDB_ARTIFACTS) $(SQL_ARTIFACTS)/create/create_mysql.sql
	sed -e 's!localhost!%!g;' < "$(SQL_ARTIFACTS)/create/create_mysql.sql" > "$@"

# https://github.com/ShinDarth/TC-JSON-API/blob/master/INSTALL.md
$(SQL_INITDB_ARTIFACTS)/002-tc-json-api-dbc.sql: $(SQL_INITDB_ARTIFACTS)
	echo "CREATE DATABASE IF NOT EXISTS dbc DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" >> "$@"
	echo "GRANT ALL PRIVILEGES ON dbc . * TO '$(DB_USERNAME)'@'%' WITH GRANT OPTION;" >> "$@"

# https://github.com/ShinDarth/TC-JSON-API/blob/master/INSTALL.md
$(SQL_INITDB_ARTIFACTS)/003-tc-json-api-dbc-achievements.sql: $(SQL_INITDB_ARTIFACTS)
	echo "USE dbc;" > "$@"
	curl -sSL https://raw.githubusercontent.com/ShinDarth/TC-JSON-API/master/storage/database/achievements.sql >> "$@"

# https://github.com/Sarjuuk/aowow/blob/master/README.md
$(SQL_INITDB_ARTIFACTS)/004-aowow.sql: $(SQL_INITDB_ARTIFACTS)
	echo "CREATE DATABASE IF NOT EXISTS aowow DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" >> "$@"
	echo "GRANT ALL PRIVILEGES ON aowow . * TO '$(DB_USERNAME)'@'%' WITH GRANT OPTION;" >> "$@"

# https://github.com/Sarjuuk/aowow/blob/master/README.md
$(SQL_INITDB_ARTIFACTS)/005-aowow-db-structures.sql: $(SQL_INITDB_ARTIFACTS)
	echo "USE aowow;" > "$@"
	curl -sSL https://raw.githubusercontent.com/Sarjuuk/aowow/master/setup/db_structure.sql >> "$@"

# Create custom SQL file for to be imported on first run that inserts a default
# account username and password will full GM permissions.
$(SQL_ADD_GM_USER): $(SQL_ARTIFACTS)/custom
	@printf 'REPLACE INTO account (id,username,sha_pass_hash) VALUES (%s, "%s", SHA1(CONCAT(UPPER("%s"),":",UPPER("%s"))));\n' \
		"$(DEFAULT_GM_ID)" "$(DEFAULT_GM_USER)" "$(DEFAULT_GM_USER)" "$(DEFAULT_GM_PASSWORD)" > "$@"
	@echo "REPLACE INTO account_access (id,gmlevel,RealmID) VALUES ($(DEFAULT_GM_ID),3,-1);" >> "$@"

# Create custom SQL file to be imported on first run that updates the IP
# address of the worldserver to be something other than just localhost.
$(SQL_FIX_REALMLIST): $(SQL_ARTIFACTS)/custom
	printf 'REPLACE INTO realmlist (id,name,address,port) VALUES ("%s","%s","%s","%s");\n' \
		"$(WORLDSERVER_REALM_ID)" "$(WORLDSERVER_NAME)" \
		"$(shell hostname -i | egrep -o '[0-9\.]{7,15}')" \
		"$(WORLDSERVER_PORT)"	> "$@"

# Copy binary build artifacts in to Docker container build directories.
docker/%:
	cp "$(ARTIFACTS)/bin/$(notdir $@)" "$@"

# DEB and RPM packaging up of mapdata files for later easier re-installation.
$(MAP_DATA_RPM) $(MAP_DATA_DEB): $(MAP_DATA)
	cd $(ARTIFACTS) && fpm \
		--input-type dir \
		--output-type "$(PKG_TYPE)" \
		--name trinitycore-mapdata --version "$(BRANCH)" \
		--iteration "$(SHORT_HASH)" \
		--verbose \
		--url "https://www.trinitycore.org" \
		--maintainer "TrinityCore" \
		--category "Amusements/Games" \
		--vendor "TrinityCore" \
		--description "TrinityCore world server map data" \
		--architecture "all" \
		--directories "$(INSTALL_PREFIX)/$(MAP_DATA_DIR)" \
		$(MAP_DATA_DIR)=$(INSTALL_PREFIX)

