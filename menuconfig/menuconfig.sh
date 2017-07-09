#!/usr/bin/env bash

set -euo pipefail

if [[ ${BASH_VERSINFO[0]} -lt 4 ]] || \
   [[ ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -lt 2 ]]; then
  >&2 echo "Bash version 4.2 or higher is required to run thisscript; exiting!"
  exit 1
fi

if ! type -P dialog >/dev/null 2>&1; then
  >&2 echo "Missing dependency 'dialog'; exiting!"
  exit 1
fi

exec 3>&1
trap 'declare rc=$?; set +xvu
      >&2 echo "Unexpected error executing $BASH_COMMAND at ${BASH_SOURCE[0]} line $LINENO"
      exit $rc' ERR

is_true () {
  [[ "${1:-}" =~ ^yes|on|enabled?|true|1$ ]]
}

is_false () {
  [[ "${1:-}" =~ ^no|off|disabled?|false|0$ ]]
}

dialog () {
  declare title=""
  if [[ ! "$*" =~ --title\ [a-zA-Z0-9]+ ]]; then
    title="$(caller 0)"
    title="${title#* }"; title="${title%% *}"; title="${title//_/ }"
  fi
	command dialog \
    --backtitle "${BACK_TITLE}${changes:+ (unsaved changes)}" \
    ${title:+--title "$title"} \
    "$@" 2>&1 1>&3
}

firstrun () {
  declare file=""
  for file in "${BASH_SOURCE[0]%/*}"/firstrun[0-9]*.txt; do
    echo "$file"
	  dialog --title "${FIRSTRUN_TITLE}" --msgbox \
      "$(< "$file")" 0 0 || return 1
  done
}

write_config () {
  declare file="$1"
  declare var=""
  compgen -v TCMC_ | while read -r var; do
    printf 'declare -g %s=%q\n' "$var" "${!var}"
  done > "${file}.tmp"
  mv "${file}.tmp" "${file}"

  cp "${DOCKERFILES%//}/docker-compose.yaml" "$TCMC_DOCKER_COMPOSE_CONF"
}

read_config () {
  declare file="$1"
  declare -g config="$file"
  for config in "${PWD%/*}/$file" "${BASH_SOURCE[0]%/*}/$file"; do
    if [[ -r "$config" ]]; then
      source "$config" || continue
      return 0
    fi
  done
  return 1
}

discard_changes () {
  declare config="$1"
  compgen -v TCMC_ | while read -r var; do
    declare -g $var=""
  done
  read_config "$config" || true
}

msgbox () {
  dialog --title "$1" --msgbox "$2" 0 0
}

docker_compose_up () {
  true
}

Configure_Database () {
  true
}

compile () {
  true
}

docker_compose_up () {
  pushd "${TCMC_DOCKER_COMPOSE_CONF%/*}"
  docker-compose -f "${TCMC_DOCKER_COMPOSE_CONF##*/}" up
  popd
}

Main_Menu () {
  declare opt=""
  declare rc=0
  while [[ "$opt" != "Quit" && $rc -eq 0 ]]; do
    TCMC_DB_EXTERNAL=""
    if [[ -z "${TCMC_COMP_DATABASE:-}" ]]; then
      TCMC_DB_EXTERNAL=1
    fi

    declare nochanges=""
    if [[ -z "$changes" ]]; then nochanges=true; fi

    opt="$(dialog --trim --menu "$(< "${BASH_SOURCE[0]%/*}/mainmenu.txt")" \
      0 60 0 \
      "Components" "Change component selections" \
      "Settings" "Change configuration settings" \
      ${TCMC_DB_EXTERNAL:+"Database" "Configure external database"} \
      "Display" "Display current configuration" \
      ${changes:+"Save" "Save all configuration changes"} \
      ${changes:+"Discard" "Discard all configuration changes"} \
      "Compile" "Build TrinityCore programs and map data" \
      ${nochanges:+"Start" "Start selected Docker containers" } \
      "Help" "Display introductary help messages" \
      "Quit" "Quit to shell${changes:+ discarding all changes}" \
      )" || rc=$?
    case "$opt" in
      Help) firstrun ;;
      Database) Configure_Database ;;
      Start) docker_compose_up "${TCMC_DOCKER_COMPOSE_CONF}" ;;
      Display)
        msgbox "${TCMC_DOCKER_COMPOSE_CONF}" "$(< "${TCMC_DOCKER_COMPOSE_CONF}")"
        ;;
      Save)
        if write_config "$config"; then
          changes=""
        else
          msgbox "Error" \
            "Configuration could not be saved to $config and ${TCMC_DOCKER_COMPOSE_CONF}."
        fi
        ;;
      Discard)
        if ! discard_changes "$config" && changes="" ; then
          msgbox "Error" "Encountered an unexpected error."
          return 1
        fi
        ;;
      Components)
        Select_Components || return $?
        ;;
    esac
  done
}

Select_Components () {
  declare -a options
  declare compdef=""
  for compdef in "${DOCKERFILES%%/}"/*/menuconfig.sh.in; do
    source "$compdef" || true
    declare comp_flag="TCMC_COMP_${NAME^^}"
    options+=("$NAME" "$(printf '%-13s: %s' "$TITLE" "$SUMMARY")" "${!comp_flag:-OFF}")
  done

  declare rc=0
  declare comps=""
  comps="$(dialog --trim --checklist \
    "$(< "${BASH_SOURCE[0]%/*}/components.txt")" 0 0 0 \
    "${options[@]}")" || rc=$?

  declare -A selected_comp_flag=()
  declare comp=""
  for comp in $comps; do
    declare comp_flag="TCMC_COMP_${comp^^}"
    selected_comp_flag[$comp_flag]=1
    if [[ -z "${!comp_flag:-}" ]]; then
      changes=true
    fi
    declare -g $comp_flag=ON
  done

  while read -r comp_flag; do
    if [[ -z "${selected_comp_flag[$comp_flag]:-}" ]]; then
      if [[ -n "${!comp_flag:-}" ]]; then
        changes=true
      fi
      declare -g $comp_flag=""
    fi
  done < <(compgen -v TCMC_COMP_)
}

main () {
	source "${BASH_SOURCE[0]%/*}/base.sh.in"
  declare changes=""
  declare config="config.sh.in"
  read_config "$config" || true

  if ! is_false "${TCMC_FIRSTRUN:-}"; then
    firstrun || return $?
    Select_Components || return $?
  fi

  if [[ -z "${TCMC_FIRSTRUN:-}" ]]; then
    TCMC_FIRSTRUN=0
    changes=true
  fi

  Main_Menu || return $?
}

main "$@"

