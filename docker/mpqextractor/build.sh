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

# We only expect to have to use this when the MPQExtractor build breaks.
drop_to_shell() {
  echo ""
  if [[ -n "${cmdarg_cfg[reference]:-}" ]]; then
    echo -e "\033[0m  => \033[31mRef. sources are in:   \033[1m${cmdarg_cfg[reference]:-}"
  fi
  echo -e "\033[0m  => \033[31mSources are in:        \033[1m${cmdarg_cfg[source]%/}"
  echo -e "\033[0m  => \033[31mBuild root is in:      \033[1m${cmdarg_cfg[source]%/}/MPQExtractor/build"
  echo -e "\033[0m  => \033[31mInput WoW game client: \033[1m${cmdarg_cfg[input]}"
  echo -e "\033[0m  => \033[31mOutput data artifacts: \033[1m${cmdarg_cfg[output]}"
  echo -e "\033[0m  => \033[31mTools are in:          \033[1m${cmdarg_cfg[output]%/}/bin"
  echo -e "\033[0m  => \033[31mBuild script is:       \033[1m$(cat /proc/$$/cmdline | tr '\000' ' ')"
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
  cmdarg_info "header" "MPQ Extractor Dockerised build wrapper."
  cmdarg_info "version" "1.0"

  cmdarg_info "author" "Nicola Worthington <nicolaw@tfb.net>."
  cmdarg_info "copyright" "(C) 2017 Nicola Worthington."

  cmdarg_info "footer" \
    "See https://github.com/Kanma/MPQExtractor, https://github.com/Sarjuuk/aowow/," \
    "https://github.com/neechbear/trinitycore, https://neech.me.uk," \
    "https://github.com/neechbear/tcadmin, https://nicolaw.uk/#WoW," \
    "https://github.com/neechbear/trinitycore/blob/master/GettingStarted.md."

  cmdarg 'i:'   'input'     'Input directory containing WoW game client (and Data sub-directory)' '/World_of_Warcraft' is_directory
  cmdarg 'o:'   'output'    'Output directory for finished build artifacts' '/artifacts' is_directory
  cmdarg 'r:'   'repo'      'Git repository to clone from' 'https://github.com/Kanma/MPQExtractor'
  cmdarg 'S?'   'source'    'Source code download and build root' '/usr/local/src' is_directory
  cmdarg 'R?'   'reference' 'Cached reference Git repository on local machine'
  cmdarg 's'    'shell'     'Drop to a command line shell on errors'
  cmdarg 'v'    'verbose'   'Print more verbose debugging output'

  cmdarg_parse "$@" || return $?
}

download_source() {
  declare target="${1%/}"
  declare repo_url="$2"

  declare repo_dir="$target/MPQExtractor"
  if [[ ! -e "$repo_dir" ]]; then
    git clone --depth 1 --single-branch --recursive \
      ${cmdarg_cfg[reference]:+--reference "${cmdarg_cfg[reference]}"} \
      "$repo_url" "$repo_dir"
  else
    git -C "$repo_dir" pull
    git -C "$repo_dir" submodule init
    git -C "$repo_dir" submodule update
  fi
}

build() {
  mkdir -p "${cmdarg_cfg[source]%/}/MPQExtractor/build"
  pushd "${cmdarg_cfg[source]%/}/MPQExtractor/build"

  declare parallel_jobs="$(nproc)"
  cmake \
    "-DMPQEXTRACTOR_BINARY_DIR=${cmdarg_cfg[output]}" \
    "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${cmdarg_cfg[output]}" \
    ../
  make -j "${parallel_jobs:-1}"
  make install

  popd
}

main() {
  # Parse command line options.
  declare -gA cmdarg_cfg=()
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
  download_source "${cmdarg_cfg[source]}" "${cmdarg_cfg[repo]}"

  # Build MPQExtractor.
  build

  # Save Git revision.
  git -C "${cmdarg_cfg[source]%/}/MPQExtractor" rev-parse HEAD > "${cmdarg_cfg[output]%/}/git-rev"
  git -C "${cmdarg_cfg[source]%/}/MPQExtractor" rev-parse --short HEAD > "${cmdarg_cfg[output]%/}/git-rev-short"

  # Extract the MPQ files.
  if [[ -n "${cmdarg_cfg[shell]:-}" ]]; then
    drop_to_shell
  else
    extract_mpq_files "${cmdarg_cfg[input]}" "${cmdarg_cfg[output]}"
  fi

  # "This should be OK for us."
  # https://nicolaw.uk/this_should_be_OK_for_us
  find "${cmdarg_cfg[output]}" -type d -exec chmod a+x '{}' \;
  chmod -R a+rw "${cmdarg_cfg[output]%/}/"*
}

main "$@"

