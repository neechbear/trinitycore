#!/usr/bin/env bash

set -euo pipefail
if ! source /usr/lib/blip.bash ; then
  >&2 echo "Missing dependency 'blip' (https://nicolaw.uk/blip); exiting!"
  exit 2
fi

_parse_command_line_arguments () {
  cmdarg_info "header" "TrinityCore Dockerised build wrapper."
  cmdarg_info "version" "1.0"

  cmdarg_info "author" "Nicola Worthington <nicolaw@tfb.net>."
  cmdarg_info "copyright" "(C) 2017 Nicola Worthington."

  cmdarg_info "footer" \
    "See https://github.com/neechbear/trinitycore, https://neech.me.uk and"
    "https://nicolaw.uk/#WoW."

  cmdarg 'b'  'branch'  'Branch (version) of TrinityCore to build' '3.3.5'
  cmdarg 'r'  'repo'    'Git repository to clone from' 'https://github.com/TrinityCore/TrinityCore.git'
  cmdarg 'd?' 'tdb'     'TDB database archive URL to use'
  cmdarg 'v'  'verbose' 'Print more verbose debugging output'

  cmdarg_parse "$@" || return $?
}

get_tdb_url() {
  declare tag="${1:-TDB}"
  # https://developer.github.com/v3/
  # https://github.com/TrinityCore/TrinityCore/releases
  curl -sSL ${GITHUB_USER:+"-u$GITHUB_USER:$GITHUB_PASS"} \
    "${GITHUB_API:-https://api.github.com}/repos/${GITHUB_REPO:-TrinityCore/TrinityCore}/releases" \
    | jq -r "\"tdb_url=\" + ( [
                .[] | select(
                .tag_name | contains( \"$tag\" ) )
                .assets[] .browser_download_url
              ] | max )"
}

download_source() {
  declare target="${1%/}"
  declare branch="$2"
  declare tdb_url="${3:-}"

  declare repo_url="https://github.com/${GITHUB_REPO%%.git}.git"

  # Determine what TDB database archive URL to download.
  if ! is_url "$tdb_url"; then
    if [[ "$tdb_url" =~ "TDB"* ]]; then
      tdb_tag="$tdb_url"
    else
      tdb_tag="${branch//[^0-9]/}"
    fi
  fi
  if [[ -z "${tdb_url:-}" ]] ; then
    declare $(get_tdb_url "$tdb_tag")
    echo "$tdb_url" > "$target/database.url"
  fi

  log_notice "Fetchhing $branch ($tdb_tag) ..."
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
  declare -gA cmdarg_cfg=()
  _parse_command_line_arguments "$@" || exit $?

  if [[ -n "${cmdarg_cfg[verbose]}" || -n "${DEBUG:-}" ]] ; then
    for i in "${!cmdarg_cfg[@]}" ; do
      printf '${cmdarg_cfg[%s]}=%q\n' "$i" "${cmdarg_cfg[$i]}"
    done
  fi

  declare source="/usr/local/src/${cmdarg_cfg[branch]}"
  mkdir -p "$source"

  download_source "$source" "${cmdarg_cfg[branch]}"

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
  mkdir -p "$source/trinitycore/build"
  cd "$source/trinitycore/build"

  declare cpus="$(nproc)"
  cmake ../ -DPREFIX=/artifacts -DTOOLS=1 -DWITH_WARNINGS=0 -Wno-dev ${boost_opts}
  make -j "${cpus:-1}"
  make install
  bash -i
}

main "$@"

