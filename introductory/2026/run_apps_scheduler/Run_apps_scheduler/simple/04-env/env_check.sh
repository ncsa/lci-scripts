#!/bin/bash
# env_check.sh - Display Slurm environment variables
echo "=== Slurm Environment ==="
echo "Job ID:          $SLURM_JOB_ID"
echo "Job Name:        $SLURM_JOB_NAME"
echo "Number of Tasks: $SLURM_NTASKS"
echo "Number of Nodes: $SLURM_JOB_NUM_NODES"
echo "Node List:       $SLURM_JOB_NODELIST"
echo "CPUs per Node:   $SLURM_JOB_CPUS_PER_NODE"
echo "Partition:       $SLURM_JOB_PARTITION"
echo "Working Dir:     $SLURM_SUBMIT_DIR"
echo "========================="
