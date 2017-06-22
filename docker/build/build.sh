#!/usr/bin/env bash

set -euo pipefail

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
  declare cpus="$(nproc)"

  # If you are rate-limited, pass GITHUB_USER and GITHUB_PASS to the container.
  # Authenticated API calls have a much higher query quota.
  declare GITHUB_USER="${GITHUB_USER:-}"
  declare GITHUB_PASS="${GITHUB_PASS:-}"
  declare GITHUB_API="https://api.github.com"
  declare GITHUB_REPO="TrinityCore/TrinityCore"

  declare version="${1:-3.3.5}"
  declare source="${BASH_SOURCE[0]%/*}/build/$version"
  declare artifacts="${BASH_SOURCE[0]%/*}/artifacts/$version"

  mkdir -p "$source" "$artifacts"

  download_source "$source" "$version"
  mkdir build
  cd build

  # https://askubuntu.com/questions/828989/cmake-cant-find-boost
  declare boost_opts=""
  declare pkg=""
  for pkg in system filesystem thread program_options iostreams regex
  do
    declare pkg_path="/usr/include/boost/${pkg}"
    if [[ -d "$pkg_path" ]]; then
      boost_opts+="-DBoost_${pkg^^}_LIBRARY=$pkg_path "
    fi
  done

  # https://trinitycore.atlassian.net/wiki/display/tc/Linux+Core+Installation
  cmake ../ -DPREFIX=/artifacts -DTOOLS=1 -DWITH_WARNINGS=0 -Wno-dev ${boost_opts}
  make -j "${cpus:-1}"
  make install
  bash -i
}

main "$@"

