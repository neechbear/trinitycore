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
  echo -e "\033[0m  => \033[31mSources are in:      \033[1m${cmdarg_cfg[source]%/}"
  echo -e "\033[0m  => \033[31mBuild root is in:    \033[1m${cmdarg_cfg[source]%/}/TrinityCore/build"
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
    "https://hub.docker.com/r/nicolaw/trinitycore," \
    "https://www.youtube.com/channel/UCXDKo2buioQu_cqwIrxODpQ," \
    "https://www.youtube.com/watch?v=JmzZdexSYaM and" \
    "https://github.com/neechbear/trinitycore/blob/master/GettingStarted.md."

  cmdarg 'o:'   'output'    'Output directory for finished build artifacts' '/artifacts' is_directory
  cmdarg 'b:'   'branch'    'Branch (version) of TrinityCore to build' '3.3.5'
  cmdarg 't?'   'tdb'       'TDB database release archive URL to download'
  cmdarg 'r:'   'repo'      'Git repository to clone from' 'https://github.com/TrinityCore/TrinityCore.git'
  cmdarg 'S?'   'source'    'Source code download and build root' '/usr/local/src' is_directory
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
    | jq -r --arg tag "$tag" '[
                .[]
                | select( .tag_name | contains( $tag ) )
                | select( .assets[0].browser_download_url | endswith( ".7z" ) )
                .assets[] .browser_download_url
              ] | max'
}

extract_7z_archives() {
  declare path="$1"
  pushd "$path"
  (
    shopt -s nullglob
    if declare zips=("${path%/}"/*.7z) && [[ -n "${zips[@]}" ]]; then
      zip=""
      for zip in "${zips[@]}"; do
        7zr x -y "$zip"
      done
    fi
    shopt -u nullglob
  )
  # mv TDB_*/* .
  # rmdir TDB_*/
  popd
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
    tdb_url="$(get_tdb_url "$tdb_tag")"
  fi

  log_notice "Fetching $branch ${tdb_tag:+($tdb_tag) }..."
  log_info " -> $repo_url ($branch branch)"
  log_info " -> $tdb_url"

  declare repo_dir="$target/TrinityCore"
  # https://github.com/TrinityCore/TrinityCore/blob/master/cmake/genrev.cmake
  # https://git-scm.com/docs/git-describe
  if [[ ! -e "$repo_dir" ]]; then
      #--shallow-since="$(date +%F -d "6 months ago")" \
    git clone \
      --branch "$branch" --single-branch \
      ${cmdarg_cfg[reference]:+--reference "${cmdarg_cfg[reference]}"} \
      "$repo_url" "$repo_dir"
  else
    git -C "$repo_dir" pull
  fi

  if [[ ! -s "$repo_dir/sql/${tdb_url##*/}" ]]; then
    mkdir -p "$repo_dir/sql"
    echo "Downloading database $tdb_url ..."
    curl -L --progress-bar -o "$repo_dir/sql/${tdb_url##*/}" "$tdb_url"
    extract_7z_archives "$repo_dir/sql"
  fi
}

define_args() {
  declare key=""
  for key in "${!define[@]}"; do
    printf -- '-D%q=%q ' "$key" "${define[$key]}"
  done
}

build() {
  mkdir -p "${cmdarg_cfg[source]%/}/TrinityCore/build"
  pushd "${cmdarg_cfg[source]%/}/TrinityCore/build"

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

  # ${cmdarg_cfg[clang]} to change compiler to clang.
  # TODO: Fix this so it properly flips between clang and gcc. I've not read the
  #       documentation yet, so I don't know what I'm doing. This is a quick
  #       hack to get it working for someone else.
  if [[ "${cmdarg_cfg[clang]}" == true ]]; then
    update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100
  #else
  #  update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
  #  update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100
  fi

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

  popd
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
  download_source "${cmdarg_cfg[source]}" \
    "${cmdarg_cfg[branch]}" "${cmdarg_cfg[repo]}" "${cmdarg_cfg[tdb]}"

  # Build TrinityCore.
  build

  # Copy build artifacts to output directory.
  cp -r "${define[CMAKE_INSTALL_PREFIX]%/}"/* "${cmdarg_cfg[output]%/}"/

  # Copy SQL artifacts to output directory.
  mkdir -p "${cmdarg_cfg[output]%/}/sql"
  cp -r "${cmdarg_cfg[source]%/}/TrinityCore/sql/"* "${cmdarg_cfg[output]%/}/sql/"

  # Save Git revision.
  git -C "${cmdarg_cfg[source]%/}/TrinityCore" rev-parse HEAD > "${cmdarg_cfg[output]%/}/git-rev"
  git -C "${cmdarg_cfg[source]%/}/TrinityCore" rev-parse --short HEAD > "${cmdarg_cfg[output]%/}/git-rev-short"

  # "This should be OK for us."
  # https://nicolaw.uk/this_should_be_OK_for_us
  find "${cmdarg_cfg[output]}" -type d -exec chmod a+x '{}' \;
  chmod -R a+rw "${cmdarg_cfg[output]%/}/"*
}

main "$@"

