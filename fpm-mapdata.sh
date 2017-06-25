#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -euo pipefail

package() {
  declare source="$1"
  declare type="${2:-deb}"

  # https://fpm.readthedocs.io/en/latest/source/dir.html
  fpm \
    --input-type dir \
    --output-type deb \
    --name trinitycore-mapdata --version 3.3.5 \
    --verbose \
    --url="https://www.trinitycore.org" \ 
    --category "Amusements/Games" \
    --vendor "TrinityCore"
    --directories "/opt/trinitycore/$source" \
    "$source"=/opt/trinitycore
}

main() {
  pushd "${BASH_SOURCE[0]%/*}/artifacts/mapdata"
  package "dbc" "deb"
  popd
}

main "$@"

