
INSTALL_PREFIX = /opt/trinitycore
MAPDATA_DIR = $(INSTALL_PREFIX)/mapdata

DBHOST = mariadb
DBPORT = 3306

PKGTYPE = deb

TOOLS = mapextractor mmaps_generator vmap4assembler vmap4extractor
BINARIES = $(addprefix artifacts/bin/, $(TOOLS) authserver worldserver)
CONF = $(addprefix artifacts/etc/, authserver.conf worldserver.conf)

BRANCH := $(shell cat artifacts/branch 2>/dev/null)
BRANCH := $(if $(BRANCH),$(BRANCH), 3.3.5)
SHORTHASH := $(shell cat artifacts/git-rev-short)

MAPDATA = $(addprefix artifacts/mapdata/, Buildings Cameras dbc maps mmaps vmaps)

GAMEDATA := World_of_Warcraft

TDB_FILES := $(notdir $(wildcard artifacts/sql/TDB_*/*.sql))
TDB_WORLDSERVER_FILES = $(addprefix docker/worldserver/, $(TDB_FILES))

SQL_IMPORT := artifacts/sql/import/001-permissions.sql

MPQ = $(addprefix $(GAMEDATA)/Data/, $(addsuffix .MPQ, \
	common expansion patch-3 patch-2 patch common-2 lichking \
	enUS/lichking-speech-enUS enUS/expansion-speech-enUS enUS/lichking-locale-enUS \
	enUS/expansion-locale-enUS enUS/base-enUS enUS/patch-enUS-2 enUS/backup-enUS \
	enUS/speech-enUS enUS/patch-enUS-3 enUS/patch-enUS enUS/locale-enUS ) )

.PHONY: run build clean help mapdata_deb mapdata_rpm mapdata
.DEFAULT_GOAL := help

help:
	echo "$(TDB_DB_FILES)"
	@echo ""
	@echo "Use 'make build' to build the TrinityCore server binaries."
	@echo "Use 'make mapdata' to generate worldserver map data from the WoW game client."
	@echo "Use 'make run' to launch the TrinityCore servers inside a Docker swarm."
	@echo "Use 'make clean' to destroy all build artifacts from the above steps."
	@echo ""
	@echo "Refer to https://github.com/neechbear/trinitycore for additional help."
	@echo ""

build: $(BINARIES)

run: $(CONF) $(MAPDATA) $(SQL_IMPORT) $(TDB_WORLDSERVER_FILES) docker/worldserver/worldserver docker/authserver/authserver
	cd docker/trinitycore && docker-compose up --build

mapdata: $(MAPDATA)

clean:
	rm -Rf artifacts source

$(TDB_WORLDSERVER_FILES):
	cp -r artifacts/sql/TDB_*/"$(notdir $@)" docker/worldserver

artifacts/sql/import/001-permissions.sql: artifacts/sql/create/create_mysql.sql
	mkdir -p "$(dir $@)"
	sed -e 's!localhost!%!g;' < "$<" > "$@"

artifacts/sql/create/%: build

$(CONF):
	sed -e 's!127.0.0.1;3306;!$(DBHOST);$(DBPORT);!g;' \
		  -e 's!^DataDir\s*=.*!DataDir = "$(MAPDATA_DIR)"!g;' \
			-e 's!^SourceDirectory\s*=.*!SourceDirectory = "$(INSTALL_PREFIX)"!g;' \
			-e 's!^BuildDirectory\s*=.*!BuildDirectory = "$(INSTALL_PREFIX)/source/TrinityCore/build"!g;' \
			< "$@.dist" > "$@"

artifacts/bin/%:
	docker build -t "nicolaw/trinitycore:latest" docker/build
	docker run -it --rm \
		-v "${CURDIR}/artifacts":/artifacts \
		-v "${CURDIR}/source":/usr/local/src \
		"nicolaw/trinitycore:latest" \
		--branch "$(BRANCH)" \
		--define "CMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX)" \
		--verbose

artifacts/mapdata/%: $(addprefix docker/tools/, $(TOOLS))
	docker build -t tctools docker/tools
	docker run -it --rm \
		-v "${CURDIR}/World_of_Warcraft":/World_of_Warcraft:ro \
		-v "${CURDIR}/artifacts/mapdata":/artifacts \
		"tctools" \
		--verbose

%.MPQ:
	@echo ""
	@echo "Missing $@!"
	@echo "You are missing game client data files necessary to generate worldserver map data."
	@echo "Please copy your WoW game client in to the $(GAMEDATA) directory first."
	@echo ""

docker/%:
	cp artifacts/bin/$(shell basename "$@") "$@"

mapdata_deb: PKGTYPE=deb
mapdata_deb: artifacts/trinitycore-mapdata_$(BRANCH)-$(SHORTHASH)_all.deb

mapdata_rpm: PKGTYPE=rpm
mapdata_rpm: artifacts/trinitycore-mapdata-$(BRANCH)-$(SHORTHASH).noarch.rpm

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

