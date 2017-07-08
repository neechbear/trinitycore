#!/usr/bin/env bash

set -euo pipefail

main() {
  declare cfg_cache=""
  for cfg_cache in "${PWD%/*}/config.sh" "${BASH_SOURCE[0]%/*}/config.sh"; do
    if [[ -r "$cfg_cache" ]]; then
      source "$cfg_cache" || true
    fi
  done
}



main "$@"

