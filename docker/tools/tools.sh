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
  {
  echo ""
  echo -e "\033[0;36mFor instructions on map, visual map and movement map" \
          "creation, please see the TrinityCore documentation wiki at" \
          "https://goo.gl/wVUKrK."
  echo ""
  echo -e "\033[0m  => \033[31mTools are in: \033[1m$PWD"
  echo ""
  echo -e "\033[0mType \"\033[31;1mcompgen -v\033[0m\" or \"\033[31;1mtypeset -x\033[0m\" to list variables."
  echo -e "\033[0mType \"\033[31;1mexit\033[0m\" or press \033[31;1mControl-D\033[0m to finish."
  echo ""
  } | fold -w 80 -s
  exec "${BASH}" -i
}

log_notice() {
  echo -e "\033[0;1;33m$*\033[0m"
}

log_info() {
  echo -e "\033[0;1m$*\033[0m"
}

_parse_command_line_arguments () {
  cmdarg_info "header" "TrinityCore map extration tools wrapper."
  cmdarg_info "version" "1.0"

  cmdarg_info "author" "Nicola Worthington <nicolaw@tfb.net>."
  cmdarg_info "copyright" "(C) 2017 Nicola Worthington."

  cmdarg_info "footer" \
    "See https://github.com/neechbear/trinitycore, https://neech.me.uk," \
    "https://github.com/neechbear/tcadmin, https://nicolaw.uk/#WoW," \
    "https://hub.docker.com/r/nicolaw/trinitycore and." \
    "https://www.youtube.com/channel/UCXDKo2buioQu_cqwIrxODpQ."

  cmdarg 'v'    'verbose'   'Print more verbose debugging output'

  cmdarg_parse "$@" || return $?
}

main() {
  # Passthrough if the first argument is executable.
  if [[ $# -ge 1 && -x "${1:-}" ]] && declare cmd="${1:-}" ; then
    shift; [[ ! "$cmd" =~ / ]] && cmd="./$cmd"
    exec "$cmd" "$@"
  fi

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

  # For the time being (until this script is completed), just drop to the shell
  # regardless of the command line arguments that we parsed.
  drop_to_shell
}

main "$@"

