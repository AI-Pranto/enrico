#!/usr/bin/env bash
set -ex

mkdir -p tests/singlerod/short/build
cd tests/singlerod/short/build
echo $(which mpicxx)
echo $(cmake --version)
echo $(/usr/bin/mpicxx -show)
CC=$(which mpicc) CXX=$(which mpicxx) FC=$(which mpif90) \
  cmake -DCMAKE_CXX_COMPILER=/usr/bin/mpicxx -DCMAKE_C_COMPILER=/usr/bin/mpicc -DCMAKE_Fortran_COMPILER=/usr/bin/mpifort -DUSE_FOAM=ON -DUSR_LOC=../ ../../../..
