#!/bin/bash

#SBATCH --job-name=queue_fill
#SBATCH --output=fill_%j.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:05:00

echo "Queue fill job $SLURM_JOB_ID started at $(date)"
echo "Running on $HOSTNAME"
sleep 120
echo "Queue fill job $SLURM_JOB_ID finished at $(date)"
