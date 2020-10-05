#!/usr/bin/env bash
set -e

curdir="$(pwd)"

if [ "$MODE" = "openmc_nek5000" ]; then
  source ci/test_singlerod_openmc.sh
  cd "$curdir"
  source ci/test_singlerod_nek5000.sh
  cd "$curdir"
  source ci/test_singlerod_openmc_nek5000.sh
elif [ "$MODE" = "openmc_openfoam" ]; then
  source ci/test_singlerod_openmc_openfoam.sh
elif [ "$MODE" = "openmc_heat_surrogate" ]; then
  source ci/test_singlerod_openmc_heat_surrogate.sh
else
  echo "Invalid test mode (provided MODE=\"$MODE\""
  exit 1
fi
