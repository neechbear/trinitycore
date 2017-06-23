#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

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
    "See https://github.com/neechbear/trinitycore, https://neech.me.uk," \
    "https://github.com/neechbear/tcadmin, https://nicolaw.uk/#WoW and" \
    "https://hub.docker.com/r/nicolaw/trinitycore."

  cmdarg 'o:'   'output'   'Output directory for finished build artifacts' '/artifacts'
  cmdarg 'b:'   'branch'   'Branch (version) of TrinityCore to build' '3.3.5'
  cmdarg 'r:'   'repo'     'Git repository to clone from' 'https://github.com/TrinityCore/TrinityCore.git'
  cmdarg 't?'   'tdb'      'TDB database release archive URL to download'
  cmdarg 'D?[]' 'define'   'Supply additional -D arguments to cmake'
  cmdarg 'd'    'debug'    'Produce a debug build'
  cmdarg 'c'    'clang'    'Use clang compiler instead of gcc'
  cmdarg 'v'    'verbose'  'Print more verbose debugging output'

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

log_notice() {
  echo -e "\033[0;1;33m$*\033[0m"
}

log_info() {
  echo -e "\033[0;1m$*\033[0m"
}

download_source() {
  declare target="${1%/}"
  declare branch="$2"
  declare repo_url="$3"
  declare tdb_url="${4:-}"

  # Determine what TDB database archive URL to download.
  if ! url_exists "$tdb_url"; then
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

  log_notice "Fetching $branch ($tdb_tag) ..."
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
  declare -ga define=()
  _parse_command_line_arguments "$@" || exit $?

  if [[ -n "${cmdarg_cfg[verbose]}" || -n "${DEBUG:-}" ]] ; then
    for i in "${!cmdarg_cfg[@]}" ; do
      printf '${cmdarg_cfg[%s]}=%q\n' "$i" "${cmdarg_cfg[$i]}"
    done
  fi
  if [[ -n "${cmdarg_cfg[help]:-}" ]]; then
    exit 0
  fi

  declare source="/usr/local/src/${cmdarg_cfg[branch]}"
  mkdir -p "$source"

  download_source "$source" \
    "${cmdarg_cfg[branch]}" "${cmdarg_cfg[repo]}" "${cmdarg_cfg[tdb]}"

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

  if [[ "${cmdarg_cfg[debug]}" == true ]]; then
    :
  # TODO: Work out what extra debug stuff to add from
  #       https://travis-ci.org/TrinityCore/TrinityCore/jobs/245949532/config
  #       https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
  #  "cmake ../ -DWITH_WARNINGS=1 -DWITH_COREDEBUG=0 -DUSE_COREPCH=1
  #  -DUSE_SCRIPTPCH=1 -DTOOLS=1 -DSCRIPTS=dynamic -DSERVERS=1 -DNOJEM=1
  #  -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_FLAGS=\"-Werror\"
  #  -DCMAKE_CXX_FLAGS=\"-Werror\" -DCMAKE_C_FLAGS_DEBUG=\"-DNDEBUG\"
  #  -DCMAKE_CXX_FLAGS_DEBUG=\"-DNDEBUG\"
  #  -DCMAKE_INSTALL_PREFIX=check_install",
  fi

  # TODO: Add support for ${cmdarg_cfg[clang]} to change compiler to clang.

  # TODO: Add support for ${define[@]} -D values passed to cmake.

  declare cpus="$(nproc)"
  cmake ../ -DPREFIX=/artifacts -DTOOLS=1 -DWITH_WARNINGS=0 -Wno-dev ${boost_opts}
  make -j "${cpus:-1}"
  make install
  bash -i
}

main "$@"

