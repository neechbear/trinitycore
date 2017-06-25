#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -euo pipefail

ufw_applications() {
  cat <<EOM
TrinityCore AuthServer
TrinityCore BattleNet
TrinityCore WorldServer
TrinityCore WorldServer RA
TrinityCore WorldServer SOAP
EOM
}

my_networks() {
  cat "${BASH_SOURCE[0]%/*}/.networks"
}

main() {
  declare app="" net=""
  while read -r net ; do
    while read -r app ; do
      ufw allow from "$net" to any app "$app"
    done < <(ufw_applications)
  done < <(my_networks)
}

main "$@"
