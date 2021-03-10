# MIT License
# Copyright (c) 2017-2021 Nicola Worthington <nicolaw@tfb.net>

# TODO: Add a convenient menuconfig diaglog target?

.PHONY: test build image mapdata veryclean clean server

.DEFAULT_GOAL := test

FLAVOUR=slim

# TODO: Possibly inject these into the docker build with --build-arg.
GITHUB_REPO = TrinityCore/TrinityCore
GITHUB_API = https://api.github.com
GIT_BRANCH = 3.3.5
GIT_REPO = https://github.com/$(GITHUB_REPO).git

VCS_REF = $(shell git rev-parse HEAD)
BUILD_DATE = $(shell date --rfc-3339=seconds)
BUILD_VERSION = $(shell cat VERSION)

# https://github.com/TrinityCore/TrinityCore/releases
# TODO: Pull down the full TDB SQL dump into ./sql/
TDB_FULL_URL = $(shell curl \
	-sSL $${GITHUB_USER:+"-u$$GITHUB_USER:$$GITHUB_PASS"} "$(GITHUB_API)/repos/$(GITHUB_REPO)/releases" \
	| jq -r --arg tag "$$tag" '[.[]|select(.tag_name|contains($$tag))|select(.assets[0].browser_download_url|endswith(".7z")).assets[].browser_download_url]|max')

IMAGE_TAG = $(GIT_BRANCH)-$(FLAVOUR)
IMAGE_NAME = nicolaw/trinitycore:$(IMAGE_TAG)

clean:
	true

server:
	docker-compose up

veryclean:
	docker-compose down || true
	docker-compose rm -sfv || true
	docker volume rm trinitycore_db-data || true

image:
	# TODO: Replace $$PWD with a calculated $(MAKEFILE_DIR).
	docker build -f Dockerfile $$PWD -t $(IMAGE_NAME) \
	--build-arg FLAVOUR=$(FLAVOUR) \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE="$(BUILD_DATE)" \
	--build-arg BUILD_VERSION=$(BUILD_VERSION)
	docker inspect $(IMAGE_NAME) | jq -r '.[0].Config.Labels'

test:
	docker run --rm -it $(IMAGE_NAME)

mapdata: World_of_Warcraft
	mkdir -pv mapdata
	eval $$(docker inspect $(IMAGE_NAME) | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.mapextractor"')
	eval $$(docker inspect $(IMAGE_NAME) | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.vmap4extractor"')
	eval $$(docker inspect $(IMAGE_NAME) | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.vmap4assembler"')
	eval $$(docker inspect $(IMAGE_NAME) | jq -r '.[0].Config.Labels."org.label-schema.docker.cmd.mmaps_generator"')

