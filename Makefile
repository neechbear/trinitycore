# MIT License
# Copyright (c) 2017-2021 Nicola Worthington <nicolaw@tfb.net>
# https://github.com/neechbear/trinitycore

# TODO: Add a convenient menuconfig diaglog target?

.PHONY: test build mapdata clean run tdb sql pull
.PHONY: build-all pull-all publish-all
.DEFAULT_GOAL := help

# Flavour image to build. Defaults to "sql" for easy use with bundled
# docker-compose.yaml.
#FLAVOUR=slim
FLAVOUR=sql
#FLAVOUR=full

# Where this Makefile resides.
MAKEFILE = $(firstword $(MAKEFILE_LIST))
MAKEFILE_DIR = $(dir $(MAKEFILE))

# What realm ID and port should the worldserver identify itself as.
WORLDSERVER_REALM_ID = 2
WORLDSERVER_PORT = 8085
WORLDSERVER_IP = $(shell hostname -I | egrep -o '[0-9\.]{7,15}' | grep -v ^127. | head -1)
WORLDSERVER_NAME = $(shell hostname -s | sed -e "s/\b\(.\)/\u\1/g")

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

# SHA of upstream TrinityCore source that has been built (used for publishing).
BUILT_UPSTREAM_SHA = $(shell docker run --rm $(IMAGE_NAME) cat /.git-rev-short)

# Full database dump for the worldserver to populate the "world" database table with.
# https://github.com/TrinityCore/TrinityCore/releases
# TODO: Omit GIT_BRANCH slug suffix from TDB_RELEASE_TAG when it is "master".
TDB_RELEASE_TAG = TDB$(shell echo "$(GIT_BRANCH)" | tr -cd '[0-9]')
TDB_FULL_URL_CACHE = $(MAKEFILE_DIR).tdb_full_url.$(TDB_RELEASE_TAG)
TDB_FULL_URL = $(shell cat "$(TDB_FULL_URL_CACHE)" 2>/dev/null || curl \
       -sSL $${GITHUB_USER:+"-u$$GITHUB_USER:$$GITHUB_PASS"} "$(GITHUB_API)/repos/$(GITHUB_REPO)/releases" \
       | jq -r --arg tag "$(TDB_RELEASE_TAG)" '[.[]|select(.tag_name|contains($$tag))|select(.assets[0].browser_download_url|endswith(".7z")).assets[].browser_download_url]|max' \
       | tee "$(TDB_FULL_URL_CACHE)")
TDB_7ZIP_FILE = $(notdir $(TDB_FULL_URL))
TDB_SQL_FILE = $(patsubst %.7z,%.sql,$(TDB_7ZIP_FILE))

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

$(TDB_SQL_FILE): $(TDB_7ZIP_FILE)
	test -s "$@" || { cd $(MAKEFILE_DIR) && 7zr x -y -- "$<"; }
	test -s "$@" && touch "$@"

$(TDB_7ZIP_FILE):
	$(MAKEFILE_DIR)gettdb

help:
	@echo ""
	@echo "Use 'make build' to build the TrinityCore container image."
	@echo "Use 'make pull' to download the TrinityCore container image instead of building it."
	@echo "Use 'make test' to launch an interactive shell inside the TrinityCore container."
	@echo "Use 'make mapdata' to generate worldserver map data from the WoW game client."
	@echo "Use 'make run' to launch the TrinityCore servers inside a Docker swarm."
	@echo "Use 'make tdb' to download the full worldserver database SQL dump. (Optional)"
	@echo "Use 'make dumpdb' to create an SQL dump backup of the dataases. (Optional)"
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
	$(RM) $(TDB_FULL_URL_CACHE)

run: $(MAP_DATA_DIR)mmaps sql/custom/auth/0002-fix-realmlist.sql
	docker-compose up

# Create custom SQL file to be imported on first run that updates the IP
# address of the worldserver to be something other than just localhost.
# https://trinitycore.atlassian.net/wiki/spaces/tc/pages/2130016/realmlist
sql/custom/auth/0002-fix-realmlist.sql:
	printf 'REPLACE INTO realmlist (id,name,address,port) VALUES ("%s","%s","%s","%s");\n' \
		"$(WORLDSERVER_REALM_ID)" "$(WORLDSERVER_NAME)" "$(WORLDSERVER_IP)" "$(WORLDSERVER_PORT)" > "$@"

build:
	docker build -f Dockerfile $(MAKEFILE_DIR) -t $(IMAGE_NAME) \
	--build-arg FLAVOUR="$(FLAVOUR)" \
	--build-arg GIT_BRANCH="$(GIT_BRANCH)" \
	--build-arg GIT_REPO="$(GIT_REPO)" \
	--build-arg VCS_REF="$(VCS_REF)" \
	--build-arg BUILD_DATE="$(BUILD_DATE)" \
	--build-arg BUILD_VERSION="$(BUILD_VERSION)" \
	--build-arg TDB_FULL_URL="$(TDB_FULL_URL)"
	docker inspect $(IMAGE_NAME) | jq -r '.[0].Config.Labels'

build-all:
	$(MAKE) -f $(MAKEFILE) build FLAVOUR=slim
	$(MAKE) -f $(MAKEFILE) build FLAVOUR=sql
	$(MAKE) -f $(MAKEFILE) build FLAVOUR=full

pull:
	docker pull $(IMAGE_NAME)

pull-all:
	$(MAKE) -f $(MAKEFILE) pull FLAVOUR=slim
	$(MAKE) -f $(MAKEFILE) pull FLAVOUR=sql
	$(MAKE) -f $(MAKEFILE) pull FLAVOUR=full

publish:
	docker tag $(IMAGE_NAME) $(IMAGE_NAME)-$(BUILT_UPSTREAM_SHA)
	docker push $(IMAGE_NAME)-$(BUILT_UPSTREAM_SHA)

publish-all:
	$(MAKE) -f $(MAKEFILE) publish FLAVOUR=slim
	$(MAKE) -f $(MAKEFILE) publish FLAVOUR=sql
	$(MAKE) -f $(MAKEFILE) publish FLAVOUR=full

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

# Convenience database backup target.
MYSQL_USER = trinity
MYSQL_PWD = trinity
MYSQL_HOST = 127.0.0.1
MYSQL_TCP_PORT = 3306
MYSQLDUMP_CMD = MYSQL_PWD=$(MYSQL_PWD) mysqldump -h $(MYSQL_HOST) -P $(MYSQL_TCP_PORT) -u $(MYSQL_USER) --hex-blob

.PHONY: dumpdb
dumpdb: auth-realmlist.sql auth-account.sql auth.sql characters.sql db-auth.sql db-characters.sql
	@echo
	ls -lah $^
	@echo
	@echo "Use 'make db-world.sql' to to backup the world database (usually only necessary when explicitly customised)."
	@echo

.PHONY: auth.sql characters.sql
auth.sql characters.sql:
	$(MYSQLDUMP_CMD) --no-create-info --insert-ignore --compact --no-create-db --ignore-table=$(basename $@).build_info --ignore-table=$(basename $@).updates --ignore-table=$(basename $@).updates_include --ignore-table=$(basename $@).uptime --databases $(basename $@) > $@

.PHONY: auth-realmlist.sql auth-account.sql
auth-realmlist.sql auth-account.sql:
	$(MYSQLDUMP_CMD) --no-create-info --replace --compact --no-create-db auth $(shell echo $(basename $@) | sed 's/^auth-//') > $@

.PHONY: db-auth.sql db-world.sql db-characters.sql
db-auth.sql db-world.sql db-characters.sql:
	$(MYSQLDUMP_CMD) $(shell echo $(basename $@) | sed 's/^db-//') > $@

