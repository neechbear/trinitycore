#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -euo pipefail

package() {
  declare source="$1"
  declare type="${2:-deb}"

  # https://fpm.readthedocs.io/en/latest/source/dir.html
  set -xv

  fpm \
    --input-type dir \
    --output-type "$type" \
    --name trinitycore-mapdata --version 3.3.5 \
    --iteration "$(< git-rev-short)" \
    --verbose \
    --url "https://www.trinitycore.org" \
    --maintainer "TrinityCore" \
    --category "Amusements/Games" \
    --vendor "TrinityCore" \
    --description "TrinityCore world server map data" \
    --architecture "all" \
    --directories "/opt/trinitycore/$source" \
    "$source"=/opt/trinitycore

  { set +xv; } >/dev/null 2>&1
}

main() {
  if ! type -P fpm >/dev/null 2>&1 ; then
    >&2 echo "Install fpm first (see https://fpm.readthedocs.io/); exiting!"
    exit 1
  fi

  pushd "${BASH_SOURCE[0]%/*}/artifacts"
  package "mapdata" "${1:-deb}"
  popd
}

main "$@"

