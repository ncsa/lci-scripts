#!/bin/bash

#SBATCH --job-name=env_check
#SBATCH --output=env.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:01:00

./env_check.sh
