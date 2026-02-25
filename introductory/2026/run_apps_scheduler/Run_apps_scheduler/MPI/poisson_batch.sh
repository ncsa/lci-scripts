#!/bin/bash

#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

ulimit -s unlimited
srun --mpi=pmix poisson_mpi.x 1024 0.00001
