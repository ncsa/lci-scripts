# Run Applications via Scheduler Lab

This directory contains materials for learning how to submit and manage jobs using the Slurm job scheduler.

## Files Overview

### `Lab_Run_Application_via_Scheduler.md`
Comprehensive lab guide with detailed instructions for running applications through Slurm. Covers:
- Creating Slurm accounts and users (`sacctmgr`)
- Monitoring cluster resources (`sinfo`, `squeue`)
- Interactive job allocation (`salloc`)
- Running interactive jobs (`srun`)
- Submitting batch scripts (`sbatch`)
- Canceling jobs (`scancel`)
- Managing concurrent jobs and resources
- Monitoring running jobs (`sstat`)
- Job accounting and statistics (`sacct`)
- Cluster configuration and job information (`scontrol`)
- OpenMP and MPI application examples

### `commands`
Quick reference file containing all commands in a script-like format for easy execution. Includes:
- Creating Linux user `mpiuser` across all nodes
- Copying lab code to user directories
- Setting up Slurm accounts and associations
- All Slurm commands for resource allocation, job submission, monitoring, and accounting

## Workflow

**Quick Start:**
1. **Open `commands`** - Copy and execute the command sequence
2. **Replace cluster number** - Update XX with your cluster number where needed
3. **Run through examples** - Execute OpenMP and MPI job submissions

**Detailed Learning:**
1. **Read `Lab_Run_Application_via_Scheduler.md`** - Follow the complete lab instructions with explanations
2. **Practice each command** - Learn how to allocate resources, submit jobs, and monitor execution
3. **Explore batch scripts** - Understand how to write efficient submit scripts for different workloads

## Prerequisites

- Slurm scheduler installed and configured (see scheduler_installation/ lab)
- Head node and compute nodes properly configured
- OpenMP and MPI applications compiled and available
- User accounts created with consistent UIDs across the cluster
