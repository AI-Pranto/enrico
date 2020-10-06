cmake_minimum_required(VERSION 3.10)
project(enrico Fortran C CXX)

option(USE_NEK  "Determines if Nek5000 will be included" ON)
option(USE_FOAM  "Determines if OpenFOAM will be included" OFF)
option(BUILD_FOAM "Build vendored version of OpenFOAM" OFF)

# On BG/Q, linking requires -dynamic, not -rdynamic
if (CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "ppc64")
  set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "-dynamic")
endif ()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

# Build shared libraries by default
set(BUILD_SHARED_LIBS ON)

# =============================================================================
# Check for SCALE (optional)
# =============================================================================
find_package(SCALE PATHS ${SCALE_DIR} COMPONENTS Shift OmnibusDriver Tpetra)

if (SCALE_FOUND)
    MESSAGE(STATUS "SCALE found!")
    MESSAGE(STATUS "SCALE_DIR = ${SCALE_DIR}")
    MESSAGE(STATUS "SCALE_VERSION = ${SCALE_VERSION}")
endif ()

# =============================================================================
# Discover name-mangling for routines in libnek5000
# =============================================================================
if (USE_NEK)
    include(FortranCInterface)
    FortranCInterface_VERIFY()
    FortranCInterface_HEADER(${CMAKE_BINARY_DIR}/nek_mangling.h
        MACRO_NAMESPACE C2F_
        SYMBOL_NAMESPACE C2F_
        SYMBOLS
        nek_init
        nek_end
        nek_solve)
endif()

# =============================================================================
# Headers for all targets
# =============================================================================
include_directories(
    include/
    vendor/iapws/include
    vendor/openmc/include
    vendor
    src/
    ${CMAKE_BINARY_DIR})

if (SCALE_FOUND)
    include_directories(${SCALE_INCLUDE_DIRS})
    include_directories(${SCALE_TPL_INCLUDE_DIRS})
endif ()

# =============================================================================
# Recursively build libnek5000 and libopenmc
# =============================================================================
if (USE_NEK)
    add_subdirectory(vendor/nek5000)
endif()

add_subdirectory(vendor/openmc)

# =============================================================================
# Build OpenFOAM
# =============================================================================
if (USE_FOAM)

  set(MPI_ASSUME_NO_BUILTIN_MPI TRUE) # ensure CMake sets all relevant MPI variables
  find_package(MPI REQUIRED)

  # some adjustments to the linking flags and libraries so they can be passed to
  # the OpenFOAM build script successfully
  string(REPLACE " " "," MPI_ARCH_FLAGS "${MPI_CXX_LINK_FLAGS}")
  string(REPLACE ";" " " MPI_ARCH_LIBS "${MPI_CXX_LIBRARIES}")
  set($ENV{WM_MPLIB} "SYSTEMMPI")

  set(OPENFOAM_DIR ${CMAKE_SOURCE_DIR}/vendor/OpenFOAM-dev)
  message(STATUS "$ENV{MAKEFLAGS}")

  # set config environment variables for the execute process command below
  set(ENV{WM_MPLIB} SYSTEMMPI)
  set(ENV{MPI_ARCH_FLAGS} ${MPI_CXX_LINK_FLAGS})
  set(ENV{MPI_ARCH_INC} -I${MPI_CXX_INCLUDE_DIRS})
  set(ENV{MPI_ARCH_LIBS} ${MPI_ARCH_LIBS})
  set(ENV{MPI_ROOT} ${MPI_CXX_INCLUDE_DIRS}/../../)
  set(ENV{MPI_ARCH_PATH} ${MPI_CXX_INCLUDE_DIRS}/../../)
  execute_process(
  WORKING_DIRECTORY ${OPENFOAM_DIR}
  COMMAND bash -c "source etc/bashrc && echo $FOAM_LIBBIN"
  OUTPUT_VARIABLE OPENFOAM_LINK_DIRS
  OUTPUT_STRIP_TRAILING_WHITESPACE)

  message(STATUS ${MPI_CXX_LINK_FLAGS})
  message(STATUS -I${MPI_CXX_INCLUDE_DIRS})
  message(STATUS ${MPI_ARCH_LIBS})
  message(STATUS ${MPI_CXX_INCLUDE_DIRS}/../../)
  message(STATUS ${MPI_CXX_INCLUDE_DIRS}/../../)

  # create a custom target for building OpenFOAM
  add_custom_target(OpenFOAM-build
  WORKING_DIRECTORY ${OPENFOAM_DIR}
  COMMAND
  WM_MPLIB=SYSTEMMPI
  MPI_ARCH_FLAGS=${MPI_CXX_LINK_FLAGS}
  MPI_ARCH_INC=-I${MPI_CXX_INCLUDE_DIRS}
  MPI_ARCH_LIBS=${MPI_ARCH_LIBS}
  MPI_ROOT=${MPI_CXX_INCLUDE_DIRS}/../../
  MPI_ARCH_PATH=${MPI_CXX_INCLUDE_DIRS}/../../
  MAKEFLAGS="-j10"
  bash -c 'cd ${OPENFOAM_DIR} && source etc/bashrc && ./Allwmake && echo $FOAM_LIBBIN > ${CMAKE_CURRENT_BINARY_DIR}/FOAM_LIBS.txt')

  set(OPENFOAM_SRC ${OPENFOAM_DIR}/src/)

  # removed -m64 flag from this list
  set(OPENFOAM_DEFINITIONS -Dlinux64 -DWM_ARCH_OPTION=64 -DWM_DP -DWM_LABEL_SIZE=32 -DNoRepository)
  set(OPENFOAM_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Xlinker --no-as-needed -Xlinker --add-needed")

  set(CHT_DIR ${OPENFOAM_DIR}/applications/solvers/heatTransfer/chtMultiRegionFoam/)
  set(OPENFOAM_SOURCES ${CHT_DIR}/solid/solidRegionDiffNo.C ${CHT_DIR}/fluid/compressibleCourantNo.C)

  set(OPENFOAM_INCLUDE_DIRS
  ${CHT_DIR}/
  ${CHT_DIR}/fluid/
  ${CHT_DIR}/solid/
  ${CHT_DIR}/porousFluid/
  ${CHT_DIR}/porousSolid/
  ${CHT_DIR}/include/
  ${OPENFOAM_SRC}/meshTools/lnInclude/
  ${OPENFOAM_SRC}/sampling/lnInclude/
  ${OPENFOAM_SRC}/finiteVolume/lnInclude/
  ${OPENFOAM_SRC}/finiteVolume/cfdTools/
  ${OPENFOAM_SRC}/thermophysicalModels/basic/lnInclude/
  ${OPENFOAM_SRC}/thermophysicalModels/specie/lnInclude/
  ${OPENFOAM_SRC}/thermophysicalModels/reactionThermo/lnInclude/
  ${OPENFOAM_SRC}/thermophysicalModels/solidThermo/lnInclude/
  ${OPENFOAM_SRC}/thermophysicalModels/chemistryModel/lnInclude/
  ${OPENFOAM_SRC}/ODE/lnInclude/
  ${OPENFOAM_SRC}/combustionModels/lnInclude/
  ${OPENFOAM_SRC}/MomentumTransportModels/momentumTransportModels/lnInclude/
  ${OPENFOAM_SRC}/MomentumTransportModels/compressible/lnInclude/
  ${OPENFOAM_SRC}/ThermophysicalTransportModels/lnInclude/
  ${OPENFOAM_SRC}/ThermophysicalTransportModels/rhoReactionThermo/lnInclude/
  ${OPENFOAM_SRC}/radiationModels/lnInclude/
  ${OPENFOAM_SRC}/regionModels/regionModel/lnInclude/
  ${OPENFOAM_SRC}/OpenFOAM/lnInclude/
  ${OPENFOAM_SRC}/OSspecific/POSIX/lnInclude/
  )

  set(OPENFOAM_LIBRARY_NAMES
  fluidThermophysicalModels
  specie
  reactionThermophysicalModels
  solidThermo
  chemistryModel
  ODE
  combustionModels
  momentumTransportModels
  fluidThermoMomentumTransportModels
  thermophysicalTransportModels
  rhoReactionThermophysicalTransportModels
  meshTools
  finiteVolume
  radiationModels
  fvOptions
  regionModels
  sampling
  OpenFOAM
  )

  set(OPENFOAM_MPI_LIBS Pstream)

  add_library(OpenFOAM-combined-lib SHARED ${OPENFOAM_SOURCES})
  add_dependencies(OpenFOAM-combined-lib OpenFOAM-build)

  # get absolute paths of the necessary librares
  foreach(FOAM_LIB ${OPENFOAM_LIBRARY_NAMES})
    add_library("${FOAM_LIB}_LIB" SHARED IMPORTED GLOBAL)
    set_target_properties("${FOAM_LIB}_LIB" PROPERTIES IMPORTED_LOCATION ${OPENFOAM_LINK_DIRS}/lib${FOAM_LIB}${CMAKE_SHARED_LIBRARY_SUFFIX})
    add_dependencies("${FOAM_LIB}_LIB" OpenFOAM-build)
    list(APPEND OPENFOAM_LIBRARIES "${FOAM_LIB}_LIB")
  endforeach(FOAM_LIB ${OPENFOAM_LIBRARY_NAMES})

  foreach(FOAM_LIB ${OPENFOAM_MPI_LIBS})
    add_library("${FOAM_LIB}_LIB" SHARED IMPORTED GLOBAL)
    set_target_properties("${FOAM_LIB}_LIB" PROPERTIES IMPORTED_LOCATION ${OPENFOAM_LINK_DIRS}/mpi-system/lib${FOAM_LIB}${CMAKE_SHARED_LIBRARY_SUFFIX})
    add_dependencies("${FOAM_LIB}_LIB" OpenFOAM-build)
    list(APPEND OPENFOAM_LIBRARIES "${FOAM_LIB}_LIB")
  endforeach(FOAM_LIB ${OPENFOAM_MPI_LIBS})

  target_compile_definitions(OpenFOAM-combined-lib PUBLIC ${OPENFOAM_DEFINITIONS})
  set_target_properties(OpenFOAM-combined-lib PROPERTIES LINK_FLAGS ${OPENFOAM_LINKER_FLAGS})
  target_link_libraries(OpenFOAM-combined-lib ${OPENFOAM_LIBRARIES})
  target_include_directories(OpenFOAM-combined-lib PUBLIC ${OPENFOAM_INCLUDE_DIRS})

endif()

# =============================================================================
# IAPWS Correlations
# =============================================================================
add_library(iapws vendor/iapws/iapws.cpp)
target_link_libraries(iapws PRIVATE gsl-lite)
target_compile_definitions(iapws PRIVATE GSL_THROW_ON_CONTRACT_VIOLATION)

# =============================================================================
# Heat transfer surrogate
# =============================================================================
add_library(heat_xfer vendor/surrogates/heat_xfer_backend.cpp)
target_include_directories(heat_xfer PUBLIC vendor/surrogates/)
target_link_libraries(heat_xfer PUBLIC iapws)

# =============================================================================
# Build libenrico
# =============================================================================

set(SOURCES
    src/driver.cpp
    src/coupled_driver.cpp
    src/comm_split.cpp
    src/surrogate_heat_driver.cpp
    src/mpi_types.cpp
    src/openmc_driver.cpp
    src/cell_instance.cpp
    src/vtk_viz.cpp
    src/heat_fluids_driver.cpp)

if (USE_NEK)
    list(APPEND SOURCES src/nek_driver.cpp)
endif()

if (USE_FOAM)
  list(APPEND SOURCES src/foam_driver.cpp)
endif()

if (SCALE_FOUND)
    list(APPEND SOURCES src/shift_driver.cpp)
endif ()

# Build all compoments of libenrico
add_library(libenrico
            ${SOURCES})

set_target_properties(libenrico PROPERTIES OUTPUT_NAME enrico)
set(LIBRARIES
    iapws
    libopenmc
    xtensor
    heat_xfer
    pugixml
    gsl-lite
    ${MPI_CXX_LIBRARIES})

target_compile_definitions(libenrico PRIVATE GSL_THROW_ON_CONTRACT_VIOLATION)

if (USE_NEK)
    target_compile_definitions(libenrico PUBLIC USE_NEK)
    list(APPEND LIBRARIES libnek5000)
endif()

if (USE_FOAM)
    target_compile_definitions(libenrico PRIVATE USE_FOAM)
    list(APPEND LIBRARIES OpenFOAM-combined-lib)
endif()

if (SCALE_FOUND)
  target_compile_definitions(libenrico PRIVATE USE_SHIFT)
  list(APPEND LIBRARIES ${SCALE_LIBRARIES} ${SCALE_TPL_LIBRARIES})
endif ()

target_link_libraries(libenrico PUBLIC ${LIBRARIES})

# =============================================================================
# Build enrico driver
# =============================================================================
add_executable(enrico src/main.cpp)
target_link_libraries(enrico PUBLIC libenrico)

# =============================================================================
# Build enrico tests and demos
# =============================================================================
add_executable(comm_split_demo tests/comm_split_demo/main.cpp)

add_executable(test_openmc_singlerod tests/singlerod/short/test_openmc.cpp)
target_link_libraries(test_openmc_singlerod PUBLIC libenrico)

# Ensure C++14 standard is used
set_target_properties(
        enrico libenrico
        comm_split_demo
        heat_xfer
        iapws
        test_openmc_singlerod
        PROPERTIES CXX_STANDARD 14 CXX_EXTENSIONS OFF)


if (USE_NEK)
    add_executable(test_nek5000_singlerod tests/singlerod/short/test_nek5000.cpp)
    target_link_libraries(test_nek5000_singlerod PUBLIC libenrico)
    set_target_properties(
        test_nek5000_singlerod
        PROPERTIES CXX_STANDARD 14 CXX_EXTENSIONS OFF)
endif()

# =============================================================================
# Build unit tests
# =============================================================================
add_library(Catch INTERFACE)
target_include_directories(Catch INTERFACE vendor/catch/single_include/catch2)

add_executable(unittests
  tests/unit/catch.cpp
  tests/unit/test_surrogate_th.cpp)
target_link_libraries(unittests PUBLIC Catch pugixml libenrico)
set_target_properties(unittests PROPERTIES CXX_STANDARD 14 CXX_EXTENSIONS OFF)
