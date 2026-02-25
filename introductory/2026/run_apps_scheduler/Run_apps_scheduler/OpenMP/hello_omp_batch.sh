#!/bin/bash

#SBATCH --job-name=hello_omp
#SBATCH --output=a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:01:00

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
./hello_omp.x
