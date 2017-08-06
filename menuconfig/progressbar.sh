#!/usr/bin/env bash

set -euo pipefail

used_inodes () {
  df --output=iused "$1" | tail -1
}

join_by () {
  local IFS="$1"; shift
  echo "$*"
}

progress_bar () {
  declare total="$1" width="$2" textlines="$3" title="${4:-Progress}"

  declare -a text=($(printf '_ %.0s' { 1 .. $textlines }))
  declare -i trimchars=$(( width - 4 )) slicelines=$(( textlines - 1 ))
  declare -i height=$(( textlines + 5 ))
  declare -i count=0

  while read -r file; do
    text=("${text[@]:1:$slicelines}")
    text+=("${file:0:$trimchars}")
    count=$(( count + 1 ))
    declare -i percent=$((200*$count/$total % 2 + 100*$count/$total))
    printf 'XXX\n%s\n%s\nXXX\n' "$percent" "$(join_by $'\n' "${text[@]}")"
  done | dialog \
    --title "$title" \
    --gauge "" \
    $height $width 0
}

main () {
  declare path="${1:-/}"
  declare total=0
  total=$(used_inodes "$path")
  find "$path" -xdev | progress_bar $total 70 5
}

main "$@"

