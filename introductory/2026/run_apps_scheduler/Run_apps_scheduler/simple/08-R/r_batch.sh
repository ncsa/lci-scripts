#!/bin/bash

#SBATCH --job-name=r_array
#SBATCH --output=slurm_r_%A_%a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:02:00
#SBATCH --array=1-5

# R Array Job Example
echo "=== R Array Job Task ${SLURM_ARRAY_TASK_ID} ==="
echo "Array Job ID: ${SLURM_ARRAY_JOB_ID}"
echo "Task ID:      ${SLURM_ARRAY_TASK_ID}"
echo "Host:         $(hostname)"
echo "Date:         $(date)"
echo ""

cd /scratch/mpiuser/simple/08-R

# Create output directory if needed
mkdir -p output

# Run R script
Rscript process_data.R

echo ""
echo "R Task ${SLURM_ARRAY_TASK_ID} completed!"
