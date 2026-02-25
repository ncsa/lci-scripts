#!/bin/bash

#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

ulimit -s unlimited
srun --mpi=pmix mpi_heat2D.x
