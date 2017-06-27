
# Installation location of TrinityCore server.
INSTALL_PREFIX = /opt/trinitycore
MAPDATA_DIR = $(INSTALL_PREFIX)/mapdata

# Default username and password to create a GM user.
DEFAULT_GM_USER := trinity
DEFAULT_GM_PASSWORD := trinity

# Database hostname and port. Defaulted to Docker swarm container mariadb.
DBHOST = mariadb
DBPORT = 3306

# Package type to build for map data. (Optional step).
PKGTYPE = deb

# Enable worldserver remote access and SOAP API by default.
WORLDSERVER_RA = 1
WORLDSERVER_RA_IP = 0.0.0.0
WORLDSERVER_SOAP = 1
WORLDSERVER_SOAP_IP = 0.0.0.0

# TrinityCore binary and config files.
TOOLS = mapextractor mmaps_generator vmap4assembler vmap4extractor
BINARIES = $(addprefix artifacts/bin/, $(TOOLS) authserver worldserver)
CONF = $(addprefix artifacts/etc/, authserver.conf worldserver.conf)
DIST_CONF = $(addsuffix .dist, $(CONF))

# Version of TrinityCore we are compiling, packaging and running.
BRANCH := $(shell cat artifacts/branch 2>/dev/null)
BRANCH := $(if $(BRANCH),$(BRANCH), 3.3.5)
SHORTHASH := $(shell cat artifacts/git-rev-short 2>/dev/null)

# Location of WoW game client files, used to generate worldserver map data.
GAMEDATA := World_of_Warcraft

# Directories expected to be generated for worldserver map data.
MAPDATA = $(addprefix artifacts/mapdata/, Buildings Cameras dbc maps mmaps vmaps)

# TDB database files used by worldserver to initialise the world database.
TDB_FILES := $(notdir $(wildcard artifacts/sql/TDB_*/*.sql))
TDB_WORLDSERVER_FILES = $(addprefix docker/worldserver/, $(TDB_FILES))

# See https://hub.docker.com/_/mariadb/: Initializing a fresh instance.
SQL_IMPORT := artifacts/docker-entrypoint-initdb.d/permissions.sql

# Custom auth SQL, fixup realmlist, add GM user.
SQL_FIX_REALMLIST := artifacts/sql/custom/auth/fix_realmlist.sql
SQL_ADD_GM_USER := artifacts/sql/custom/auth/add_gm_user.sql

# Currently unused. MPQ game data files used by the map data generation tools.
# TODO: Set a proper dependency to require these if we need to build map data.
MPQ = $(addprefix $(GAMEDATA)/Data/, $(addsuffix .MPQ, \
	common expansion patch-3 patch-2 patch common-2 lichking \
	enUS/lichking-speech-enUS enUS/expansion-speech-enUS enUS/lichking-locale-enUS \
	enUS/expansion-locale-enUS enUS/base-enUS enUS/patch-enUS-2 enUS/backup-enUS \
	enUS/speech-enUS enUS/patch-enUS-3 enUS/patch-enUS enUS/locale-enUS ) )

.PHONY: run build springclean clean help mapdata_deb mapdata_rpm mapdata
.DEFAULT_GOAL := help

help:
	@echo ""
	@echo "Use 'make build' to build the TrinityCore server binaries."
	@echo "Use 'make mapdata' to generate worldserver map data from the WoW game client."
	@echo "Use 'make run' to launch the TrinityCore servers inside a Docker swarm."
	@echo "Use 'make clean' to destroy all build artifacts from the above steps."
	@echo ""
	@echo "Refer to https://github.com/neechbear/trinitycore for additional help."
	@echo ""

build: $(BINARIES)

run: $(CONF) $(MAPDATA) $(SQL_FIX_REALMLIST) $(SQL_ADD_GM_USER) $(SQL_IMPORT) $(TDB_WORLDSERVER_FILES) docker/worldserver/worldserver docker/authserver/authserver
	mkdir -p artifacts/mysql
	cd docker/trinitycore && docker-compose up --build

mapdata: $(MAPDATA)

clean:
	rm -Rf artifacts source

springclean:
	rm -Rf artifacts/mysql/* $(CONF) docker/worldserver/*.sql docker/worldserver/worldserver docker/authserver/authserver $(SQL_FIX_REALMLIST) $(SQL_ADD_GM_USER) $(dir $(SQL_IMPORT)) $(addprefix docker/tools/, $(TOOLS))

$(TDB_WORLDSERVER_FILES):
	cp -r artifacts/sql/TDB_*/"$(notdir $@)" docker/worldserver

$(SQL_ADD_GM_USER): artifacts/sql/custom
	@printf 'INSERT INTO account (id, username, sha_pass_hash) VALUES (%s, "%s", SHA1(CONCAT(UPPER("%s"),":",UPPER("%s"))));\n' \
		"1" "$(DEFAULT_GM_USER)" "$(DEFAULT_GM_USER)" "$(DEFAULT_GM_PASSWORD)" > "$@"
	@echo "INSERT INTO account_access VALUES (1,3,-1);" >> "$@"

$(SQL_FIX_REALMLIST): artifacts/sql/custom
	printf 'UPDATE realmlist SET address = "%s" WHERE id = 1 AND address = "127.0.0.1";\n' \
		"$(shell hostname -i | egrep -o '[0-9\.]{7,15}')" > "$@"

$(SQL_IMPORT): artifacts/sql/create/create_mysql.sql
	mkdir -p "$(dir $@)"
	sed -e 's!localhost!%!g;' < "$<" > "$@"

artifacts/sql/create/%: build

$(DIST_CONF): build

$(CONF): $(DIST_CONF)
	sed -e 's!127.0.0.1;3306;!$(DBHOST);$(DBPORT);!g;' \
		  -e 's!^DataDir\s*=.*!DataDir = "$(MAPDATA_DIR)"!g;' \
			-e 's!^SourceDirectory\s*=.*!SourceDirectory = "$(INSTALL_PREFIX)"!g;' \
			-e 's!^BuildDirectory\s*=.*!BuildDirectory = "$(INSTALL_PREFIX)/source/TrinityCore/build"!g;' \
			-e 's!^Ra\.Enable\s*=.*!Ra.Enable = $(WORLDSERVER_RA)!g;' \
			-e 's!^Ra\.IP\s*=.*!Ra.IP = "$(WORLDSERVER_RA_IP)"!g;' \
			-e 's!^SOAP\.Enabled\s*=.*!SOAP.Enabled = $(WORLDSERVER_SOAP)!g;' \
			-e 's!^SOAP\.IP\s*=.*!SOAP.IP = "$(WORLDSERVER_SOAP_IP)"!g;' \
			< "$@.dist" > "$@"

artifacts/bin/%:
	mkdir -p artifacts source
	docker build -t "nicolaw/trinitycore:latest" docker/build
	docker run -it --rm \
		-v "${CURDIR}/artifacts":/artifacts \
		-v "${CURDIR}/source":/usr/local/src \
		"nicolaw/trinitycore:latest" \
		--branch $(BRANCH) \
		--define "CMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX)" \
		--verbose

artifacts/mapdata/%: $(addprefix docker/tools/, $(TOOLS))
	mkdir -p artifacts/mapdata
	docker build -t tctools docker/tools
	docker run -it --rm \
		-v "${CURDIR}/World_of_Warcraft":/World_of_Warcraft:ro \
		-v "${CURDIR}/artifacts/mapdata":/artifacts \
		"tctools" \
		--verbose

docker/%:
	cp "artifacts/bin/$(notdir $@)" "$@"

# Not currently used.
%.MPQ:
	@echo ""
	@echo "Missing $@!"
	@echo "You are missing game client data files necessary to generate worldserver map data."
	@echo "Please copy your WoW game client in to the $(GAMEDATA) directory first."
	@echo ""

mapdata_deb: PKGTYPE=deb
mapdata_deb: artifacts/trinitycore-mapdata_$(BRANCH)-$(SHORTHASH)_all.deb

mapdata_rpm: PKGTYPE=rpm
mapdata_rpm: artifacts/trinitycore-mapdata-$(BRANCH)-$(SHORTHASH).noarch.rpm

# FIXME: Missing target can't be found properly - needs fixing.
%.deb %.rpm: artifacts/mapdata
  cd artifacts && fpm \
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
    mapdata=/opt/trinitycore

