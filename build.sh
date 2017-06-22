#!/usr/bin/env bash

set -euo pipefail

log_notice() {
  echo -e "\033[0;1;33m$*\033[0m"
}

log_info() {
  echo -e "\033[0;1m$*\033[0m"
}

get_tdb_url() {
  declare tag="${1:-TDB}"
  # https://developer.github.com/v3/
  # https://github.com/TrinityCore/TrinityCore/releases
  curl -sSL ${GITHUB_USER:+"-u$GITHUB_USER:$GITHUB_PASS"} \
    "${GITHUB_API}/repos/${GITHUB_REPO}/releases" \
    | jq -r "\"tdb_url=\" + ( [
                .[] | select(
                .tag_name | contains( \"$tag\" ) )
                .assets[] .browser_download_url
              ] | max )"
}

download_source() {
  declare target="${1%/}"
  declare branch="$2"
  declare tdb_tag="TDB${branch//[^0-9]/}"
  declare repo_url="https://github.com/${GITHUB_REPO%%.git}.git"

  log_notice "Fetchhing $branch ($tdb_tag) ..."

  if [[ -r "$target/database.url" ]]; then
    declare tdb_url="$(< "$target/database.url")"
  fi
  if [[ -z "${tdb_url:-}" ]] ; then
    declare $(get_tdb_url "$tdb_tag")
    echo "$tdb_url" > "$target/database.url"
  fi
  log_info " -> $repo_url ($branch branch)"
  log_info " -> $tdb_url"

  if [[ ! -e "$target/trinitycore" ]]; then
    git clone -b "$branch" --depth 1 \
      "$repo_url" "$target/trinitycore"
  else
    git -C "$target/trinitycore" pull
  fi

  if [[ ! -s "$target/${tdb_url##*/}" ]]; then
    echo "Downloading database $tdb_url ..."
    curl -L --progress-bar -o "$target/${tdb_url##*/}" "$tdb_url"
  fi
}

main() {
  declare GITHUB_USER="${GITHUB_USER:-}"
  declare GITHUB_PASS="${GITHUB_PASS:-}"
  declare GITHUB_API="https://api.github.com"
  declare GITHUB_REPO="TrinityCore/TrinityCore"

  declare version="${1:-3.3.5}"
  declare source="${BASH_SOURCE[0]%/*}/build/$version"
  declare artifacts="${BASH_SOURCE[0]%/*}/artifacts/$version"

  mkdir -p "$source" "$artifacts"

  download_source "$source" "$version"

  log_notice "Building Docker build container ..."
  cp docker/build/* "$source"
  docker build -t "trinitycore/build:$version" "$source"
  docker images "trinitycore/build:$version" | tee "$source/images.txt"

  log_notice "Building TrinityCore ..."
  docker run --rm -v "$(readlink -f "$artifacts")":/build "trinitycore/build:$version"
}

main "$@"

