#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -u

main() {
  "${BASH_SOURCE[0]%/*}/wait-for-it.sh" "mariadb:3306" --child
  "${BASH_SOURCE[0]%/*}/authserver"
}

main "$@"

