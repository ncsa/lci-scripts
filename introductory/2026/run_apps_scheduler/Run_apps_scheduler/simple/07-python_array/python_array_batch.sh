#!/bin/bash

#SBATCH --job-name=py_array
#SBATCH --output=slurm_py_array_%A_%a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:02:00
#SBATCH --array=1-5

# Array Job Example - Process multiple input files in parallel
# Each array task processes one input file based on SLURM_ARRAY_TASK_ID

echo "=== Array Job Task ${SLURM_ARRAY_TASK_ID} ==="
echo "Array Job ID: ${SLURM_ARRAY_JOB_ID}"
echo "Task ID:      ${SLURM_ARRAY_TASK_ID}"
echo "Host:         $(hostname)"
echo "Date:         $(date)"
echo ""

cd /scratch/mpiuser/simple

# Generate inputs if they don't exist (only task 1 does this)
if [ ! -d "input" ]; then
    if [ "$SLURM_ARRAY_TASK_ID" -eq 1 ]; then
        echo "Generating input files..."
        python3 generate_inputs.py
    fi
    # Wait for task 1 to finish generating inputs
    sleep 2
fi

# Process the input file for this task
python3 process_inputs.py ${SLURM_ARRAY_TASK_ID}

echo ""
echo "Task ${SLURM_ARRAY_TASK_ID} completed!"
