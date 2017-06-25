#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -ueo pipefail

main() {
  declare database="${1:-world}"; shift || :
  mysql -u root --password=okgreat -h 127.0.0.1 -P 3307 -D "$database" "$@"
}

main "$@"

