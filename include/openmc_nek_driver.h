//! \file openmc_nek_driver.h
//! Driver for coupled Nek5000/OpenMC simulations
#ifndef STREAM_OPENMC_NEK_DRIVER_H
#define STREAM_OPENMC_NEK_DRIVER_H

#include "base_drivers.h"
#include "mpi.h"
#include "nek_driver.h"
#include "openmc_driver.h"
#include <unordered_set>

namespace stream {

//! Driver for coupled Nek5000/OpenMC simulations
//!
//! \todo This is not actually derived from CoupledDriver.  Currently, it is unclear how or if the
//! base class will be implemented.  The issue will be revisited
class OpenmcNekDriver {
public:
  //! Given existing MPI comms, initialize drivers and geometry mappings
  //!
  //! Currently, openmc_comm and nek_comm must be subsets of coupled_comm.  The function
  //! stream::get_node_comms() can be used to split a coupled_comm into suitable subcomms.
  //!
  //! \param argc Number of command line arguments
  //! \param argv Values of command line arguments
  //! \param coupled_comm An existing communicator for the coupled driver
  //! \param openmc_comm An existing communicator for OpenMC
  //! \param nek_comm An existing communicator for Nek5000
  //! \param intranode_comm A communictor representing the intranode ranks associated with the
  //!                       calling process.  \sa stream::get_node_comms()
  OpenmcNekDriver(int argc, char* argv[], MPI_Comm coupled_comm, MPI_Comm openmc_comm,
                  MPI_Comm nek_comm, MPI_Comm intranode_comm);

  //! Does automatic destruction and nothing extra.
  ~OpenmcNekDriver() {};

  //! Transfers heat source terms from Nek5000 to OpenMC
  void update_heat_source();

  //! Tranfsers temperatures from OpenMC to Nek5000
  void update_temperature();

  Comm comm_; //!< The communicator used to run this driver
  Comm intranode_comm_;  //!< The communicator reprsenting intranode ranks
  OpenmcDriver openmc_driver_;  //!< The OpenMC driver
  NekDriver nek_driver_;  //!< The Nek5000 driver
private:
  void local_to_global();

  //! Create bidirectional mappings from OpenMC materials to/from Nek5000 elements
  void init_mappings();

  //! Initialize the tallies for all OpenMC materials
  void init_tallies();

  //! Get the heat index for a given OpenMC material
  //! \param mat_index An OpenMC material index
  //! \return The heat index
  int get_heat_index(int32_t mat_index) const
  {
    return heat_index_.at(mat_index - 1);
  }

  //! Map that gives a list of Nek element global indices for a given OpenMC material index
  std::unordered_map<int32_t, std::vector<int>> mat_to_elems_;

  //! Map that gives the OpenMC material index for a given Nek global element index
  std::unordered_map<int, int32_t> elem_to_mat_;

  //! Mapping of material indices (minus 1) to positions in array of heat sources that is used
  //! during update_heat_source
  std::vector<int> heat_index_;

  //! Number of materials in OpenMC model
  int32_t n_materials_;
};

} // namespace stream

#endif //STREAM_OPENMC_NEK_DRIVER_H
