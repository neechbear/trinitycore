# MIT License
# Copyright (c) 2017-2021 Nicola Worthington <nicolaw@tfb.net>

# TODO: Add a convenient menuconfig diaglog target?

.PHONY: test build image

.DEFAULT_GOAL := test

NPROCS = $(shell nprocs)
GITHUB_REPO = TrinityCore/TrinityCore
GITHUB_API = https://api.github.com
GIT_BRANCH = 3.3.5
GIT_REPO = https://github.com/$(GITHUB_REPO).git

# https://github.com/TrinityCore/TrinityCore/releases
TDB_FULL_URL = $(shell curl \
	-sSL $${GITHUB_USER:+"-u$$GITHUB_USER:$$GITHUB_PASS"} "$(GITHUB_API)/repos/$(GITHUB_REPO)/releases" \
	| jq -r --arg tag "$$tag" '[.[]|select(.tag_name|contains($$tag))|select(.assets[0].browser_download_url|endswith(".7z")).assets[].browser_download_url]|max')

IMAGE_TAG = latest
IMAGE_NAME = tc:$(IMAGE_TAG)

image:
	docker build -f Dockerfile $$PWD -t $(IMAGE_NAME)

test:
	docker run --rm -it $(IMAGE_NAME)

# TODO: Remove. (Unused). See Dockerfile multistage build instead.
build:
	git clone --branch $(GIT_BRANCH) --single-branch $(GIT_REPO) /src
	mkdir -pv /src/build
	cd /src/build
	cmake ../ -DTOOLS=1 -DWITH_WARNINGS=0 -DCMAKE_INSTALL_PREFIX=/opt/trinitycore -DCONF_DIR=/etc -Wno-dev
	make -j$(NPROC)
	make install

# TODO: Add debug options to Dockerfile multistage build debug tag flavour.
#  if [[ "${cmdarg_cfg[debug]}" == true ]]; then
#    # https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
#    # https://trinitycore.atlassian.net/wiki/display/tc/Linux+Core+Installation
#    define[WITH_WARNINGS]=1
#    define[WITH_COREDEBUG]=0 # What does this do, and why is it 0 on a debug build?
#    define[CMAKE_BUILD_TYPE]="Debug"
#    define[CMAKE_C_FLAGS]="-Werror"
#    define[CMAKE_CXX_FLAGS]="-Werror"
#    define[CMAKE_C_FLAGS_DEBUG]="-DNDEBUG"
#    define[CMAKE_CXX_FLAGS_DEBUG]="-DNDEBUG"
#  fi
#
#  declare -a extra_cmake_args=()
#  if [[ "${define[WITH_WARNINGS]}" == "0" ]]; then
#    extra_cmake_args+=("-Wno-dev")
#  fi
