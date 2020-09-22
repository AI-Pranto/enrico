#!/bin/bash

# change to directory of this script
cd "$(dirname "$0")"

CC=mpicc

export LDFLAGS="-Wl,-rpath=$(pwd)/OpenFOAM-dev/platforms/linux64GccDPInt32Opt/lib $LDFLAGS"

MPIARGS=$($CC -show)

if [[ -z $1 ]]; then
    BUILD_JOBS=1
else
    BUILD_JOBS=$1
fi

export MPI_ROOT=/usr
export MPI_ARCH_PATH=$MPI_ROOT
export MPI_ARCH_FLAGS=$(echo ${MPIARGS} | cut -d" " -f 2,3)
export MPI_ARCH_INC=$(echo ${MPIARGS} | cut -d" " -f 4)
export MPI_ARCH_LIBS=$(echo ${MPIARGS} | cut -d" " -f 5,6)
export WM_MPLIB=SYSTEMMPI

echo "MPI_ARCH_FLAGS: ${MPI_ARCH_FLAGS}"
echo "MPI_ARCH_INC: ${MPI_ARCH_INC}"
echo "MPI_ARCH_LIBS: ${MPI_ARCH_LIBS}"

cd OpenFOAM-dev

# set OpenFOAM environment
source etc/bashrc

# build OpenFOAM
./Allwmake -j $BUILD_JOBS