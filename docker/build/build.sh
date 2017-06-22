#!/usr/bin/env bash

set -euxvo pipefail

main() {
  declare cpus="$(nproc)"

  mkdir build
  cd build

  cmake ../ -DPREFIX=/artifacts -DTOOLS=1 -DWITH_WARNINGS=0
  make -j "${cpus:-1}"
  make install
}

main "$@"

