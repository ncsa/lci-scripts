#!/bin/bash

#SBATCH --job-name=array_job
#SBATCH --output=array_%A_%a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:02:00
#SBATCH --array=1-5

./array_task.sh
