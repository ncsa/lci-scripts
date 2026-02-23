# Head Node Lab

This directory contains materials for configuring the head node of an HPC cluster.

## Files Overview

### `Lab_head_node.md`
Comprehensive lab guide with detailed explanations for setting up the head node. Covers:
- Hostname configuration
- Ansible installation and playbook execution
- ClusterShell setup for parallel command execution
- Creating and propagating user groups across all nodes
- Centralized logging configuration

### `todo.md`
Quick reference command list for students who want to get started immediately. Contains only the essential commands without detailed explanations.

**Note:** Replace `XX` with your cluster number (e.g., `01`, `02`) throughout the file.

### `commands`
Reference file containing all commands in a script-like format for easy copy-paste execution.

## Workflow

**Quick Start:**
1. **Open `todo.md`** - Follow the step-by-step command list
2. **Update cluster number** - Replace `XX` with your cluster number
3. **Execute commands** - Run each step in order

**Detailed Learning:**
1. **Read `Lab_head_node.md`** - Follow the complete lab instructions with explanations
2. **Execute commands** - Follow along with the detailed guide

## Prerequisites

- Rocky Linux 9.7 installed on head node and compute nodes
- Root or sudo access
- Network connectivity between head node and compute nodes
- SSH host-based authentication already configured
