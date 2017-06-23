#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -euo pipefail

log_notice() {
  echo -e "\033[0;1;33m$*\033[0m"
}

main() {
  log_notice "Building Docker build container ..."
  docker build -t "trinitycore/build:latest" docker/build

  declare artifacts="$(readlink -f "${BASH_SOURCE[0]%/*}")/artifacts"
  mkdir -p "$artifacts"

  log_notice "Building TrinityCore ..."
  docker run -it --rm -v "$artifacts":/artifacts "trinitycore/build:latest" "$@"
}

main "$@"

