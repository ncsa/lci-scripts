#!/bin/bash

#SBATCH --job-name=hostname_job
#SBATCH --output=a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=4
#SBATCH --time=00:01:00

srun hostname_array.sh
