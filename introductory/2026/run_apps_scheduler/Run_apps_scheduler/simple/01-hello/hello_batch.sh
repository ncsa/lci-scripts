#!/bin/bash

#SBATCH --job-name=hello_job
#SBATCH --output=hello.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:01:00

./hello.sh
