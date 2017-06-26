#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -u

main() {
  "${BASH_SOURCE[0]%/*}/wait-for-it.sh" "mariadb:3306" --child
  sleep 5
  echo "Starting worldserver ..."
  "${BASH_SOURCE[0]%/*}/worldserver" || {
    >&2 echo -e "\033[0;1;31mworldserver exited with exit-code $?\033[0m"
  }
}

main "$@"

