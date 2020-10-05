#!/usr/bin/env bash
set -ex

curdir="$(pwd)"

cp -r ./config ~/.OpenFOAM
cd tests/singlerod/short/openmc_openfoam
WM_PROJECT_DIR=$curdir/vendor/OpenFOAM-dev/ ./Allmesh
mpirun -np 2 ../build/enrico


