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

is_directory() {
  [[ -d "${1:-}" ]]
}

_parse_command_line_arguments () {
  cmdarg_info "header" "TrinityCore Dockerised build wrapper."
  cmdarg_info "version" "1.0"

  cmdarg_info "author" "Nicola Worthington <nicolaw@tfb.net>."
  cmdarg_info "copyright" "(C) 2017 Nicola Worthington."

  cmdarg_info "footer" \
    "See https://github.com/neechbear/trinitycore, https://neech.me.uk," \
    "https://github.com/neechbear/tcadmin, https://nicolaw.uk/#WoW," \
    "https://hub.docker.com/r/nicolaw/trinitycore and" \
    "https://www.youtube.com/channel/UCXDKo2buioQu_cqwIrxODpQ."

  cmdarg 'o:'   'output'    'Output directory for finished build artifacts' '/artifacts' is_directory
  cmdarg 'b:'   'branch'    'Branch (version) of TrinityCore to build' '3.3.5'
  cmdarg 't?'   'tdb'       'TDB database release archive URL to download'
  cmdarg 'r:'   'repo'      'Git repository to clone from' 'https://github.com/TrinityCore/TrinityCore.git'
  cmdarg 'R?'   'reference' 'Cached reference Git repository on local machine'
  cmdarg 'D?{}' 'define'    'Supply additional -D arguments to cmake'
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

extract_7z_archives() {
  declare path="$1"
  (
    shopt -s nullglob
    if declare zips=("${path%/}"/*.7z) && [[ -n "$zips" ]]; then
      pushd "$path"
      zip=""
      for zip in "${z[@]}"; do
        p7zip -d "$zip"
      done
      popd
    fi
    shopt -u nullglob
  )
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

  cp "$target/${tdb_url##*/}" "${cmdarg_cfg[output]%/}"/
}

define_args() {
  declare key=""
  for key in "${!define[@]}"; do
    printf -- '-D%q=%q ' "$key" "${define[$key]}"
  done
}

build() {
  mkdir -p "$source/trinitycore/build"
  cd "$source/trinitycore/build"

  # Turn on --debug preset cmake arguments.
  if [[ "${cmdarg_cfg[debug]}" == true ]]; then
    # https://github.com/TrinityCore/TrinityCore/blob/master/.travis.yml
    # https://trinitycore.atlassian.net/wiki/display/tc/Linux+Core+Installation
    define[WITH_WARNINGS]=1
    define[WITH_COREDEBUG]=0 # What does this do, and why is it 0 on a debug build?
    define[CMAKE_BUILD_TYPE]="Debug"
    define[CMAKE_C_FLAGS]="-Werror"
    define[CMAKE_CXX_FLAGS]="-Werror"
    define[CMAKE_C_FLAGS_DEBUG]="-DNDEBUG"
    define[CMAKE_CXX_FLAGS_DEBUG]="-DNDEBUG"
  fi

  # Miscellaneous cmake arguments.
  declare -a extra_cmake_args=()
  if [[ "${define[WITH_WARNINGS]}" == "0" ]]; then
    extra_cmake_args+=("-Wno-dev")
  fi

  # TODO: Add support for ${cmdarg_cfg[clang]} to change compiler to clang.

  # Report our define -D settings.
  declare i=""
  for i in "${!define[@]}" ; do
    printf '${define[%q]}=%q\n' "$i" "${define[$i]}"
  done
  unset i

  log_notice "Will compile with: $(define_args)${extra_cmake_args[@]:-}"

  declare parallel_jobs="$(nproc)"
  cmake ../ $(define_args) ${extra_cmake_args[@]:-}
  make -j "${parallel_jobs:-1}"
  make install
}

main() {
  # Parse command line options.
  declare -gA cmdarg_cfg=()
  declare -gA define=(
      [TOOLS]=1
      [WITH_WARNINGS]=0
      [CMAKE_INSTALL_PREFIX]=/opt/trinitycore
    )
  _parse_command_line_arguments "$@" || exit $?

  # Report command line options and help.
  if [[ -n "${cmdarg_cfg[verbose]}" || -n "${DEBUG:-}" ]] ; then
    declare i=""
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

  # Copy build artifacts to output directory.
  cp -r "${define[CMAKE_INSTALL_PREFIX]%/}"/* "${cmdarg_cfg[output]%/}"/
  extract_7z_archives "${cmdarg_cfg[output]%/}"
}

main "$@"

