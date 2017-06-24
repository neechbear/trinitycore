#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -euo pipefail

log_error() {
  >&2 echo -e "\033[0;1;31m$*\033[0m"
}

log_notice() {
  echo -e "\033[0;1;33m$*\033[0m"
}

main() {
  # https://docs.docker.com/compose/install/
  if ! type -P docker-compose >/dev/null 2>&1 ; then
    log_error "Please install 'docker-compose' from" \
              "https://docs.docker.com/compose/ first."
  fi

  pushd "${BASH_SOURCE[0]%/*}/docker/trinitycore"
  docker-compose up
  popd
}

main "$@"

