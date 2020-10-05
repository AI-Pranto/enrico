#!/usr/bin/env bash
set -e

cd tests/singlerod/short/openmc_openfoam
# change the number of processes in the decomposition dictionary to 2
sed -i 's/numberOfSubdomains 10;/numberOfSubdomains 2;/g' $(find . -name decomposeParDict)
