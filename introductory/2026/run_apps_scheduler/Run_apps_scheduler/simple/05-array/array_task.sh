#!/bin/bash
# array_task.sh - Script for Slurm job array
# Each array task runs independently with its own SLURM_ARRAY_TASK_ID
echo "Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Array Job ID:  $SLURM_ARRAY_JOB_ID"
echo "Hostname:      $HOSTNAME"
echo "Processing item $SLURM_ARRAY_TASK_ID of $SLURM_ARRAY_TASK_COUNT"
echo "Current time:  $(date)"
sleep 5
echo "Task $SLURM_ARRAY_TASK_ID complete"
