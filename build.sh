#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -euo pipefail

log_notice() {
  echo -e "\033[0;1;33m$*\033[0m"
}

local_cache_build() {
  declare cache="$(readlink -f "${BASH_SOURCE[0]%/*}")/trinitycore-cache"
  log_notice "Caching source into $cache ..."

  # Remove source cache if we exit before we mirrored it all okay.
  trap 'rm -Rf "$cache"' EXIT

  declare tdb_archive="$cache/${2##*/}"
  if [[ ! -s "$tdb_archive" ]]; then
    curl -L -o "$tdb_archive" "$2"
  fi

  declare tdb_archive_bytes="$(stat -c %s "$tdb_archive")"
  if [[ $tdb_archive_bytes -lt 1000000 ]]; then
    >&2 echo -e "\033[0;1;31mWARNING: Database archive $tdb_archive looks" \
                "suspisciously small ($tdb_archive_bytes bytes)!\033[0m"
  fi

  if [[ ! -e "$cache" ]]; then
    git clone --bare \
       https://github.com/TrinityCore/TrinityCore.git \
      "$cache"
  else
    git -C "$cache" fetch --all --tags --prune
  fi

  trap - EXIT

  # Build with source cache (leave container behind after; no --rm).
  log_notice "Building TrinityCore using source cache in $cache ..."
  docker run -it \
    -v "$artifacts":/artifacts \
    -v "$cache":/reference \
    nicolaw/trinitycore \
      --shell --verbose --reference=/reference \
      --tdb "file:///reference/${2##*/}" "$@"
}

main() {
  log_notice "Building Docker build container ..."
  docker build -t "nicolaw/trinitycore:latest" docker/build

  declare artifacts="$(readlink -f "${BASH_SOURCE[0]%/*}")/artifacts"
  mkdir -p "$artifacts"

  if [[ $# -ge 2 && "$1" =~ ^[0-9\.]+$ && "$2" =~ ^(https?|file|ftp)://.+ ]]
  then
    local_cache_build "$@"
    return $?
  fi

  log_notice "Building TrinityCore ..."
  docker run -it --rm -v "$artifacts":/artifacts "nicolaw/trinitycore:latest" "$@"
}

main "$@"

