#!/bin/bash

#SBATCH --job-name=env_mpi
#SBATCH --output=a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=4
#SBATCH --time=00:01:00

srun --mpi=pmix ./env_mpi.x
