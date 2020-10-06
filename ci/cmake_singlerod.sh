#!/usr/bin/env bash
set -ex

mkdir -p tests/singlerod/short/build
cd tests/singlerod/short/build
echo $(cmake --version)
CC=mpicc CXX=mpicxx FC=mpif90 \
  cmake -DUSE_FOAM=ON -DUSR_LOC=../ ../../../..
