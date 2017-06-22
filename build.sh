#!/usr/bin/env bash

set -euo pipefail

log_notice() {
  echo -e "\033[0;1;33m$*\033[0m"
}

main() {
  declare version="${1:-3.3.5}"
  declare artifacts="${BASH_SOURCE[0]%/*}/artifacts/$version"

  log_notice "Building Docker build container ..."
  docker build -t "trinitycore/build:$version" docker/build

  log_notice "Building TrinityCore ..."
  mkdir -p "$artifacts"
  docker run -it --rm -v "$(readlink -f "$artifacts")":/build "trinitycore/build:$version"
}

main "$@"

