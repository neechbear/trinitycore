#!/usr/bin/env bash

set -euo pipefail

to_hash() {
  tr 'a-z' 'A-Z' | sha1sum | cut -d' ' -f1
}

main() {
  declare username="" password=""

  while [[ -z "${username// /}" || ${#username} -gt 32 ]]; do
    read -r -e -i "${username:-$USER}" -p "Username: " username
    if [[ ${#username} -gt 32 ]]; then
      >&2 echo "Username is too long; maximum length is 32 characters!"
    fi
  done

  while [[ -z "${password}" || ${#password} -gt 16 ]]; do
    read -r -e -s -p "Password: " password
    if [[ ${#password} -gt 16 ]]; then
      echo
      >&2 echo "Password is too long; maximum length is 16 characters!"
    fi
  done

  echo
  printf "$username:$password" | to_hash
}

main "$@"

