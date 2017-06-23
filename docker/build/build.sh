#!/usr/bin/env bash

# MIT License
# Copyright (c) 2017 Nicola Worthington <nicolaw@tfb.net>

set -Eauo pipefail
shopt -s extdebug

# I'm a lazy and indolent 'programmer'.
if ! source /usr/lib/blip.bash ; then
  >&2 echo "Missing dependency 'blip' (https://nicolaw.uk/blip); exiting!"
  exit 2
fi

# Stacktrace on error, with optional dump to shell.
trap 'declare rc=$?; set +xvu
      >&2 echo "Unexpected error executing $BASH_COMMAND at ${BASH_SOURCE[0]} line $LINENO"
      __blip_stacktrace__ >&2
      [[ "${cmdarg_cfg[shell]:-}" == true ]] && drop_to_shell
      exit $rc' ERR

# We only expect to have to use this when the TrinityCore build breaks.
drop_to_shell() {
  echo ""
  if [[ -n "${cmdarg_cfg[reference]:-}" ]]; then
    echo -e "\033[0m  => \033[31mRef. sources are in: \033[1m${cmdarg_cfg[reference]:-}"
  fi
  echo -e "\033[0m  => \033[31mSources are in:      \033[1m$source"
  echo -e "\033[0m  => \033[31mBuild root is in:    \033[1m$source/build"
  echo -e "\033[0m  => \033[31mArtifacts are in:    \033[1m${cmdarg_cfg[output]}"
  echo -e "\033[0m  => \033[31mBuild script is:     \033[1m$(cat /proc/$$/cmdline | tr '\000' ' ')"
  echo ""
  echo -e "\033[0mType \"\033[31;1mcompgen -v\033[0m\" or \"\033[31;1mtypeset -x\033[0m\" to list variables."
  echo -e "\033[0mType \"\033[31;1mexit\033[0m\" or press \033[31;1mControl-D\033[0m to finish."
  echo ""
  exec "${BASH}" -i
}

log_notice() {
  echo -e "\033[0;1;33m$*\033[0m"
}

log_info() {
  echo -e "\033[0;1m$*\033[0m"
}

_parse_command_line_arguments () {
  cmdarg_info "header" "TrinityCore Dockerised build wrapper."
  cmdarg_info "version" "1.0"

  cmdarg_info "author" "Nicola Worthington <nicolaw@tfb.net>."
  cmdarg_info "copyright" "(C) 2017 Nicola Worthington."

  cmdarg_info "footer" \
    "See https://github.com/neechbear/trinitycore, https://neech.me.uk," \
    "https://github.com/neechbear/tcadmin, https://nicolaw.uk/#WoW and" \
    "https://hub.docker.com/r/nicolaw/trinitycore."

  cmdarg 'o:'   'output'    'Output directory for finished build artifacts' '/artifacts'
  cmdarg 'b:'   'branch'    'Branch (version) of TrinityCore to build' '3.3.5'
  cmdarg 't?'   'tdb'       'TDB database release archive URL to download'
  cmdarg 'r:'   'repo'      'Git repository to clone from' 'https://github.com/TrinityCore/TrinityCore.git'
  cmdarg 'R?'   'reference' 'Reference Git repository on local machine'
  cmdarg 'D?[]' 'define'    'Supply additional -D arguments to cmake'
  cmdarg 'd'    'debug'     'Produce a debug build'
  cmdarg 's'    'shell'     'Drop to a command line shell on errors'
  cmdarg 'c'    'clang'     'Use clang compiler instead of gcc'
  cmdarg 'v'    'verbose'   'Print more verbose debugging output'

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

  log_notice "Fetching $branch ${tdb_tag:+($tdb_tag) }..."
  log_info " -> $repo_url ($branch branch)"
  log_info " -> $tdb_url"

  if [[ ! -e "$target/trinitycore" ]]; then
    git clone --branch "$branch" --single-branch --depth 1 \
      ${cmdarg_cfg[reference]:+--reference "${cmdarg_cfg[reference]}"} \
      "$repo_url" "$target/trinitycore"
  else
    git -C "$target/trinitycore" pull
  fi

  if [[ ! -s "$target/${tdb_url##*/}" ]]; then
    echo "Downloading database $tdb_url ..."
    curl -L --progress-bar -o "$target/${tdb_url##*/}" "$tdb_url"
  fi
}

build() {
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
  unset pkg

  # https://trinitycore.atlassian.net/wiki/display/tc/Linux+Core+Installation
  mkdir -p "$source/trinitycore/build"
  cd "$source/trinitycore/build"

  if [[ "${cmdarg_cfg[debug]}" == true ]]; then
    :
  # TODO: Work out what extra debug stuff to add from
  #       https://travis-ci.org/TrinityCore/TrinityCore/jobs/245949532/config
  #       https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
  #
  #  "cmake ../ -DWITH_WARNINGS=1 -DWITH_COREDEBUG=0 -DUSE_COREPCH=1
  #  -DUSE_SCRIPTPCH=1 -DTOOLS=1 -DSCRIPTS=dynamic -DSERVERS=1 -DNOJEM=1
  #  -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_FLAGS=\"-Werror\"
  #  -DCMAKE_CXX_FLAGS=\"-Werror\" -DCMAKE_C_FLAGS_DEBUG=\"-DNDEBUG\"
  #  -DCMAKE_CXX_FLAGS_DEBUG=\"-DNDEBUG\"
  #  -DCMAKE_INSTALL_PREFIX=check_install",
  fi

  # TODO: Add support for ${cmdarg_cfg[clang]} to change compiler to clang.

  # TODO: Add support for ${define[@]} -D values passed to cmake.

  declare parallel_jobs="$(nproc)"
  #declare log_dir="${cmdarg_cfg[output]%/}/log"
  #declare log_time="$(printf "%(%FT%T%z)T" -2)"
  #mkdir -p "$log_dir"

  # Dependency configuration.
  cmake ../ "-DPREFIX=${cmdarg_cfg[output]}" -DTOOLS=1 -DWITH_WARNINGS=0 \
    -Wno-dev ${boost_opts}
  #  2>&1 | tee -a "$log_dir/cmake-${log_time}.log"

  # Compilation
  make -j "${parallel_jobs:-1}"
  #  2>&1 | tee -a "$log_dir/make-${log_time}.log"

  # Install binaries to artifact ouput directory.
  make install
  #  2>&1 | tee -a "$log_dir/install-${log_time}.log"
}

main() {
  # Parse command line options.
  declare -gA cmdarg_cfg=()
  declare -ga define=()
  _parse_command_line_arguments "$@" || exit $?

  # Report command line options and help.
  if [[ -n "${cmdarg_cfg[verbose]}" || -n "${DEBUG:-}" ]] ; then
    for i in "${!cmdarg_cfg[@]}" ; do
      printf '${cmdarg_cfg[%s]}=%q\n' "$i" "${cmdarg_cfg[$i]}"
    done
    unset i
  fi
  if [[ -n "${cmdarg_cfg[help]:-}" ]]; then
    exit 0
  fi

  # Download source in to /usr/local/src/.
  declare -g source="/usr/local/src/${cmdarg_cfg[branch]}"
  mkdir -p "$source"
  download_source "$source" \
    "${cmdarg_cfg[branch]}" "${cmdarg_cfg[repo]}" "${cmdarg_cfg[tdb]}"

  # Build TrinityCore.
  build
}

main "$@"

