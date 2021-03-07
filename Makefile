# MIT License
# Copyright (c) 2017-2021 Nicola Worthington <nicolaw@tfb.net>

# TODO: Add a convenient menuconfig diaglog target?

.PHONY: test build mapdata clean run tdb sql pull
.DEFAULT_GOAL := help

# Flavour image to build.
FLAVOUR=slim

# Where this Makefile resides.
MAKEFILE_DIR = $(dir $(firstword $(MAKEFILE_LIST)))

# What realm ID and port should the worldserver identify itself as.
WORLDSERVER_REALM_ID = 2
WORLDSERVER_PORT = 8085
WORLDSERVER_IP = $(shell hostname -I | egrep -o '[0-9\.]{7,15}' | grep -v ^127. | head -1)
WORLDSERVER_NAME = "TrinityCore"

# Container label information.
VCS_REF = $(shell git rev-parse HEAD)
BUILD_DATE = $(shell date --rfc-3339=seconds)
BUILD_VERSION = $(shell cat VERSION)

# Where to pull the upstream TrinityCore source from.
GITHUB_REPO = TrinityCore/TrinityCore
GITHUB_API = https://api.github.com
GIT_BRANCH = 3.3.5
GIT_REPO = https://github.com/$(GITHUB_REPO).git

# What to call the resulting container image.
IMAGE_TAG = $(GIT_BRANCH)-$(FLAVOUR)
IMAGE_NAME = nicolaw/trinitycore:$(IMAGE_TAG)

# Full database dump for the worldserver to populate the "world" database table with.
# https://github.com/TrinityCore/TrinityCore/releases
# TODO: Omit GIT_BRANCH slug suffix from TDB_RELEASE_TAG when it is "master".
TDB_RELEASE_TAG = TDB$(shell echo "$(GIT_BRANCH)" | tr -cd '[0-9]')
TDB_FULL_URL = $(shell curl \
       -sSL $${GITHUB_USER:+"-u$$GITHUB_USER:$$GITHUB_PASS"} "$(GITHUB_API)/repos/$(GITHUB_REPO)/releases" \
       | jq -r --arg tag "$(TDB_RELEASE_TAG)" '[.[]|select(.tag_name|contains($$tag))|select(.assets[0].browser_download_url|endswith(".7z")).assets[].browser_download_url]|max')
TDB_SQL_FILE = $(patsubst %.7z,%.sql,$(notdir $(TDB_FULL_URL)))

# Location of WoW game client files, used to generate worldserver map data.
GAME_CLIENT_DIR = ./World_of_Warcraft/

# Directories expected to be generated for worldserver map data.
MAP_DATA_DIR = ./mapdata/

# MPQ game data files use to generate the worldserver map data.
MPQ_LOCALE = $(notdir $(shell find $(GAME_CLIENT_DIR)Data/ -mindepth 1 -maxdepth 1 -type d 2>/dev/null || echo enUS))
MPQ = $(addprefix $(GAME_CLIENT_DIR)Data/, $(addsuffix .MPQ, \
	common expansion patch-3 patch-2 patch common-2 lichking \
	$(MPQ_LOCALE)/lichking-speech-$(MPQ_LOCALE) \
	$(MPQ_LOCALE)/expansion-speech-$(MPQ_LOCALE) \
	$(MPQ_LOCALE)/lichking-locale-$(MPQ_LOCALE) \
	$(MPQ_LOCALE)/expansion-locale-$(MPQ_LOCALE) \
	$(MPQ_LOCALE)/base-$(MPQ_LOCALE) \
	$(MPQ_LOCALE)/patch-$(MPQ_LOCALE)-2 \
	$(MPQ_LOCALE)/backup-$(MPQ_LOCALE) \
	$(MPQ_LOCALE)/speech-$(MPQ_LOCALE) \
	$(MPQ_LOCALE)/patch-$(MPQ_LOCALE)-3 \
	$(MPQ_LOCALE)/patch-$(MPQ_LOCALE) \
	$(MPQ_LOCALE)/locale-$(MPQ_LOCALE) ) )

.INTERMEDIATE: $(MPQ)

tdb sql: $(TDB_SQL_FILE)

$(TDB_SQL_FILE):
	$(MAKEFILE_DIR)gettdb

help:
	@echo ""
	@echo "Use 'make build' to build the TrinityCore container image."
	@echo "Use 'make pull' to download the TrinityCore container image instead of building it."
	@echo "Use 'make test' to launch an interactive shell inside the TrinityCore container."
	@echo "Use 'make mapdata' to generate worldserver map data from the WoW game client."
	@echo "Use 'make run' to launch the TrinityCore servers inside a Docker swarm."
	@echo "Use 'make tfb' to download the full worldserver database SQL dump. (Optional)"
	@echo "Use 'make clean' to destroy ALL container images and MySQL database volume."
	@echo ""
	@echo "Refer to https://github.com/neechbear/trinitycore/blob/master/README.md for additional help."
	@echo ""

clean:
	@while [ -z "$$CONFIRM_CLEAN" ]; do \
		read -r -p "Are you sure you want to delete ALL built and intermediate container images and database volumes? [y/N]: " CONFIRM_CLEAN; \
	done; [ "$$CONFIRM_CLEAN" = "y" ]
	docker-compose down || true
	docker-compose rm -sfv || true
	docker volume rm trinitycore_db-data || true
	docker image rm "$(docker image ls --filter "label=org.label-schema.name=nicolaw/trinitycore-intermediate-build" --quiet)"
	docker image rm "$(docker image ls --filter "label=org.label-schema.name=nicolaw/trinitycore" --quiet)"

run: $(MAP_DATA_DIR)mmaps sql/custom/auth/0001-fix-realmlist.sql
	docker-compose up

# Create custom SQL file to be imported on first run that updates the IP
# address of the worldserver to be something other than just localhost.
sql/custom/auth/0001-fix-realmlist.sql:
	printf 'REPLACE INTO realmlist (id,name,address,port) VALUES ("%s","%s","%s","%s");\n' \
		"$(WORLDSERVER_REALM_ID)" "$(WORLDSERVER_NAME)" "$(WORLDSERVER_IP)" "$(WORLDSERVER_PORT)" > "$@"

build:
	docker build -f Dockerfile $(MAKEFILE_DIR) -t $(IMAGE_NAME) \
	--build-arg FLAVOUR=$(FLAVOUR) \
	--build-arg GIT_BRANCH=$(GIT_BRANCH) \
	--build-arg GIT_REPO=$(GIT_REPO) \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE="$(BUILD_DATE)" \
	--build-arg BUILD_VERSION=$(BUILD_VERSION)
	docker inspect $(IMAGE_NAME) | jq -r '.[0].Config.Labels'

pull:
	docker pull $(IMAGE_NAME)

test:
	docker run --rm -it $(IMAGE_NAME)

# Explicitly remind the user where to copy their World of Warcraft game client
# files if they are missing.
%.MPQ:
	$(error Missing $@ necessary to generate worldserver map data; please copy \
		your World of Warcraft game client in to the $(GAME_CLIENT_DIR) directory)

# Generate worldserver map data from World of Warcraft game client data inside a
# Docker container.
mapdata: $(MAP_DATA_DIR)mmaps

$(MAP_DATA_DIR)Cameras $(MAP_DATA_DIR)dbc $(MAP_DATA_DIR)maps: $(MPQ)
	docker run --rm -v $(abspath $(GAME_CLIENT_DIR)):/wow -v $(abspath $(MAP_DATA_DIR)):/mapdata -w /mapdata $(IMAGE_NAME) mapextractor -i /wow -o /mapdata -e 7 -f 0

$(MAP_DATA_DIR)Buildings: $(MPQ)
	docker run --rm -v $(abspath $(GAME_CLIENT_DIR)):/wow -v $(abspath $(MAP_DATA_DIR)):/mapdata -w /mapdata $(IMAGE_NAME) vmap4extractor -l -d /wow/Data

$(MAP_DATA_DIR)vmaps: $(MPQ) $(MAP_DATA_DIR)Buildings
	docker run --rm -v $(abspath $(GAME_CLIENT_DIR)):/wow -v $(abspath $(MAP_DATA_DIR)):/mapdata -w /mapdata $(IMAGE_NAME) vmap4assembler /mapdata/Buildings /mapdata/vmaps

$(MAP_DATA_DIR)mmaps: $(MPQ) $(MAP_DATA_DIR)maps $(MAP_DATA_DIR)vmaps
	docker run --rm -v $(abspath $(GAME_CLIENT_DIR)):/wow -v $(abspath $(MAP_DATA_DIR)):/mapdata -w /mapdata $(IMAGE_NAME) mmaps_generator

