#!/bin/bash
# hello.sh - Simple greeting script
echo "Hello from $HOSTNAME"
echo "Job ID: $SLURM_JOB_ID"
echo "Running at: $(date)"
