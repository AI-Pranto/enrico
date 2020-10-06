#!/usr/bin/env bash
set -ex

mkdir -p tests/singlerod/short/build
cd tests/singlerod/short/build
echo $(which mpicxx)
echo $(cmake --version)
CC=$(which mpicc) CXX=$(which mpic++) FC=$(which mpif90) \
  cmake -DUSE_FOAM=ON -DUSR_LOC=../ ../../../..
