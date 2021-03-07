#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -Euo pipefail

ufw_application_files() {
  echo "${BASH_SOURCE[0]%/*}"/ufw-application.d-*
}

ufw_applications() {
  declare appfile=""
  for appfile in $(ufw_application_files); do
    egrep -how '\[.+?\]' "$appfile" | tr -d '[]'
  done
}

ufw_install_applications() {
  declare instpath="$1"
  declare appfile=""
  for appfile in $(ufw_application_files); do
    declare shortname="${appfile##*/ufw-application.d-}"
    if [[ ! -e "${instpath%/}/$shortname" ]]; then
      cp -v "$appfile" "${instpath%/}/$shortname"
    fi
  done
}

my_networks() {
  if [[ -e "${BASH_SOURCE[0]%/*}/.networks" ]]; then
    cat "${BASH_SOURCE[0]%/*}/.networks"
  else
    cat <<EOM
127.0.0.1/32
10.0.0.0/8
192.168.0.0/16
172.16.0.0/12
EOM
  fi
}

main() {
  ufw_install_applications "/etc/ufw/applications.d"

  declare app="" net=""
  while read -r net ; do
    while read -r app ; do
      ufw allow from "$net" to any app "$app"
    done < <(ufw_applications)
  done < <(my_networks)
}

main "$@"

