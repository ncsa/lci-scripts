#!/bin/bash

#SBATCH --job-name=count_job
#SBATCH --output=slurm_count.out
#SBATCH --error=slurm_count.err
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:05:00

bash count.sh 20
