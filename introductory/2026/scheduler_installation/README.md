# Scheduler Installation Lab

This directory contains materials for installing and configuring the Slurm job scheduler on the HPC cluster.

## Files Overview

### `Lab-scheduler-install.md`
Comprehensive lab guide with detailed instructions for Slurm installation. Covers:
- Copying and configuring the Ansible playbook
- Running the scheduler installation playbook
- Destroy/cleanup procedures
- Verifying Slurm installation on head and compute nodes
- Testing Slurm job execution

### `commands`
Quick reference file containing all commands in a script-like format for easy execution.

### `slurmcheck.md`
Reference guide for verifying Slurm installation and troubleshooting common issues.

## Workflow

**Quick Start:**
1. **Open `commands`** - Copy and execute the command sequence
2. **Update cluster number** - Replace `01` with your cluster number in configuration files
3. **Run the playbook** - Execute the installation

**Detailed Learning:**
1. **Read `Lab-scheduler-install.md`** - Follow the complete lab instructions with explanations
2. **Verify installation** - Use `slurmcheck.md` to verify Slurm is working correctly

## Prerequisites

- Head node must be fully configured (see head_node/ lab)
- Ansible installed and configured
- ClusterShell configured
- Compute nodes accessible via SSH
