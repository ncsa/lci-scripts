#!/bin/bash

#SBATCH --job-name=hello_mpi
#SBATCH --output=a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=4
#SBATCH --time=00:01:00

srun --mpi=pmix ./hello_mpi.x
