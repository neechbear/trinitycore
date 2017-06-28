
# Default username and password to create a GM user.
DEFAULT_GM_USER = trinity
DEFAULT_GM_PASSWORD = trinity

# Database hostname and port. Defaulted to Docker swarm container mariadb.
DBHOST = mariadb
DBPORT = 3306

# Enable worldserver remote access and SOAP API by default.
WORLDSERVER_RA = 1
WORLDSERVER_RA_IP = 0.0.0.0
WORLDSERVER_SOAP = 1
WORLDSERVER_SOAP_IP = 0.0.0.0

# Location of WoW game client files, used to generate worldserver map data.
GAME_CLIENT = World_of_Warcraft

# Package type to build for map data. (Optional step).
PKGTYPE = deb

# Build artifacts output path.
ARTIFACTS = artifacts
SQL_ARTIFACTS = $(ARTIFACTS)/sql

# See https://hub.docker.com/_/mariadb/: Initializing a fresh instance.
SQL_IMPORT = $(ARTIFACTS)/docker-entrypoint-initdb.d/permissions.sql

# Custom auth SQL, fixup realmlist, add GM user.
SQL_FIX_REALMLIST = $(SQL_ARTIFACTS)/custom/auth/fix_realmlist.sql
SQL_ADD_GM_USER = $(SQL_ARTIFACTS)/custom/auth/add_gm_user.sql

# TDB database files used by worldserver to initialise the world database.
SQL_TDB = $(notdir $(wildcard $(SQL_ARTIFACTS)/TDB_*/*.sql))
SQL_TDB_WORLDSERVER = $(addprefix docker/worldserver/, $(SQL_TDB))

# Directories expected to be generated for worldserver map data.
MAP_DATA_DIR = mapdata
MAP_DATA_ARTIFACTS = $(ARTIFACTS)/$(MAP_DATA_DIR)
MAP_DATA = $(addprefix $(MAP_DATA_ARTIFACTS)/, Buildings Cameras dbc maps mmaps vmaps)

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

# Version of TrinityCore we are compiling, packaging and running.
BRANCH := $(shell cat $(ARTIFACTS)/branch 2>/dev/null)
BRANCH := $(if $(BRANCH),$(BRANCH), 3.3.5)
SHORTHASH := $(shell cat $(ARTIFACTS)/git-rev-short 2>/dev/null)


.PHONY: run build springclean clean help mapdata_deb mapdata_rpm mapdata
.INTERMEDIATE: $(addprefix docker/tools/, $(TOOLS))
.DEFAULT_GOAL := help


#
# Phony targets.
#

help:
	@echo "$(MAP_DATA)"
	@echo "Use 'make build' to build the TrinityCore server binaries."
	@echo "Use 'make mapdata' to generate worldserver map data from the WoW game client."
	@echo "Use 'make run' to launch the TrinityCore servers inside a Docker swarm."
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
	cd docker/trinitycore && docker-compose up --build

# Clean ALL artifacts, source and MariaDB / mysql database files.
clean:
	rm -Rf $(ARTIFACTS) $(SOURCE_DIR)

# Clean most things, except $(ARTIFACTS) which takes a long time to build.
springclean:
	rm -Rf $(MYSQL_ARTIFACTS) $(CONF) docker/worldserver/*.sql \
		docker/worldserver/worldserver docker/authserver/authserver \
		$(SQL_FIX_REALMLIST) $(SQL_ADD_GM_USER) $(dir $(SQL_IMPORT)) \
		$(addprefix docker/tools/, $(TOOLS))


#
# Real targets.
#

# Build TrinityCore server inside a Docker container.
$(BINARIES) $(DIST_CONF) $(SQL_ARTIFACTS)/create/%:
	mkdir -p $(ARTIFACTS) $(SOURCE_DIR)
	docker build -t "nicolaw/trinitycore:latest" docker/build
	docker run -it --rm \
		-v "${CURDIR}/$(ARTIFACTS)":/$(ARTIFACTS) \
		-v "${CURDIR}/$(SOURCE_DIR)":/usr/local/src \
		"nicolaw/trinitycore:latest" \
		--branch $(BRANCH) \
		--define "CMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX)" \
		--verbose

# Generate worldserver map data from World of Warcraft game client data inside a
# Docker container.
$(MAP_DATA): $(addprefix docker/tools/, $(TOOLS)) $(MPQ)
	mkdir -p $(ARTIFACTS)/mapdata
	docker build -t tctools docker/tools
	docker run -it --rm \
		-v "${CURDIR}/World_of_Warcraft":/World_of_Warcraft:ro \
		-v "${CURDIR}/$(ARTIFACTS)/mapdata":/$(ARTIFACTS) \
		"tctools" \
		--verbose

# Explicitly remind the user where to copy their World of Warcraft game client
# files if they are missing.
%.MPQ:
	$(error Missing $@ necessary to generate worldserver map data; please copy \
		your World of Warcraft game client in to the $(GAME_CLIENT) directory)

# Create authserver and worldserver configuration files from their default
# .conf.dist artifacts.
$(CONF): $(DIST_CONF)
	sed -e 's!127.0.0.1;3306;!$(DBHOST);$(DBPORT);!g;' \
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

# Modify create_mysql.sql to grant permissions to % instead of just localhost.
# (This is nececcary when running the database server in a different Docker
# container to the authserver and worldserver).
$(SQL_IMPORT): $(SQL_ARTIFACTS)/create/create_mysql.sql
	mkdir -p "$(dir $@)"
	sed -e 's!localhost!%!g;' < "$<" > "$@"

# Create custom SQL file for to be imported on first run that inserts a default
# account username and password will full GM permissions.
$(SQL_ADD_GM_USER): $(SQL_ARTIFACTS)/custom
	@printf 'INSERT INTO account (id, username, sha_pass_hash) VALUES (%s, "%s", SHA1(CONCAT(UPPER("%s"),":",UPPER("%s"))));\n' \
		"1" "$(DEFAULT_GM_USER)" "$(DEFAULT_GM_USER)" "$(DEFAULT_GM_PASSWORD)" > "$@"
	@echo "INSERT INTO account_access VALUES (1,3,-1);" >> "$@"

# Create custom SQL file to be imported on first run that updates the IP
# address of the worldserver to be something other than just localhost.
$(SQL_FIX_REALMLIST): $(SQL_ARTIFACTS)/custom
	printf 'UPDATE realmlist SET address = "%s" WHERE id = 1 AND address = "127.0.0.1";\n' \
		"$(shell hostname -i | egrep -o '[0-9\.]{7,15}')" > "$@"

# Copy binary build artifacts in to Docker container build directories.
docker/%:
	cp "$(ARTIFACTS)/bin/$(notdir $@)" "$@"


#
# DEB and RPM packaging up of mapdata files for later easier re-installation.
#

mapdata_deb: PKGTYPE=deb
mapdata_deb: $(ARTIFACTS)/trinitycore-mapdata_$(BRANCH)-$(SHORTHASH)_all.deb

mapdata_rpm: PKGTYPE=rpm
mapdata_rpm: $(ARTIFACTS)/trinitycore-mapdata-$(BRANCH)-$(SHORTHASH).noarch.rpm

# FIXME: Missing target can't be found properly - needs fixing.
%.deb %.rpm: $(ARTIFACTS)/mapdata
  cd $(ARTIFACTS) && fpm \
    --input-type dir \
    --output-type "$(PKGTYPE)" \
    --name trinitycore-mapdata --version "$(BRANCH)" \
    --iteration "$(SHORTHASH)" \
    --verbose \
    --url "https://www.trinitycore.org" \
    --maintainer "TrinityCore" \
    --category "Amusements/Games" \
    --vendor "TrinityCore" \
    --description "TrinityCore world server map data" \
    --architecture "all" \
    --directories "$(INSTALL_PREFIX)/mapdata" \
    mapdata=$(INSTALL_PREFIX)

