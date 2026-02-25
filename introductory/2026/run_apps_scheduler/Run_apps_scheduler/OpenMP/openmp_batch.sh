#!/bin/bash

#SBATCH --job-name=OMP_run
#SBATCH --output=slurm.out
#SBATCH --error=slurm.err
#SBATCH --partition=lcilab
#SBATCH --ntasks-per-node=2


myrun=heated_plate.x                          # executable to run

export OMP_NUM_THREADS=$SLURM_JOB_CPUS_PER_NODE  # assign the number of threads
cd /scratch/mpiuser/OpenMP

./$myrun > run.out-$SLURM_JOB_ID
