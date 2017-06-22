#!/usr/bin/env bash

set -euo pipefail

main() {
  log_notice "Building Docker build container ..."
  docker build -t "trinitycore/build:latest" docker/build

  declare artifacts="$(readlink -f "${BASH_SOURCE[0]%/*}")/artifacts"
  mkdir -p "$artifacts"

  log_notice "Building TrinityCore ..."
  docker run -it --rm -v "$artifacts":/build "trinitycore/build:latest" "$@"
}

main "$@"

