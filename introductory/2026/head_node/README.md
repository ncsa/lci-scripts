# Head Node Lab

This directory contains materials for the Head Node configuration lab of the LCI Introductory Workshop.

## Files Overview

### `todo.md` ⭐ RECOMMENDED STARTING POINT
A concise, step-by-step command reference for students who want to get started quickly. Contains only the commands needed to complete the lab without detailed explanations.

**Steps covered:**
1. Fix hostname
2. Setup SSH host-based authentication
3. Run Head Node Ansible Playbook
4. Install ClusterShell
5. Create user accounts
6. Configure central logging

**Note:** Replace `XX` with your cluster number (e.g., `01`, `02`) throughout the file. Instructions for doing this with vim or nano are included at the top.

### `Lab_head_node.md`
The comprehensive lab guide that walks students through the entire head node setup process with detailed explanations. This is the main instructional document and includes:
- Initial cluster environment verification
- Hostname configuration
- SSH host-based authentication setup
- Ansible playbook execution for automated configuration
- Manual service configuration steps (clustershell, user accounts, central logging)
- Quick reference commands at the end for post-playbook configuration

> **Note:** For a condensed list of commands only, see [`todo.md`](todo.md) in this directory.

### `Head_node_playbook/`
Contains the Ansible playbook and roles for automated head node configuration:
- `playbook.yml` - Main playbook that orchestrates all roles
- `roles/powertools/` - Enables EPEL and powertools repositories
- `roles/timesync/` - Configures timezone and NTP synchronization
- `roles/head-node_pkg_inst/` - Installs required packages (gcc, ansible, mariadb, etc.)
- `roles/head-node_nfs_server/` - Configures NFS server for user home directories

### `SSH_hostbased/`
Contains Ansible playbooks and scripts for setting up SSH host-based authentication:
- `host_based_ssh.yml` - Ansible playbook to distribute SSH config files
- `gen_hosts_equiv.sh` - Script to generate hosts.equiv file
- `ssh_key_scan.sh` - Script to collect SSH host keys

### `commands`
Reference file containing manual commands (legacy - now consolidated into `Lab_head_node.md` and `todo.md`).

## Workflow

Choose your path:

**Quick Start (Recommended):**
1. **Open `todo.md`** - Follow the step-by-step command list
2. **Update cluster number** - Replace `XX` with your cluster number
3. **Execute commands** - Run each step in order
4. **Verify setup** - Confirm all services are running correctly

**Detailed Learning:**
1. **Read `Lab_head_node.md`** - Follow the complete lab instructions with explanations
2. **Run the Head_node_playbook** - Execute automated configuration: `ansible-playbook Head_node_playbook/playbook.yml`
3. **Execute manual steps** - Complete configuration from the "Quick Reference Commands" section
4. **Verify setup** - Confirm all services are running correctly

## Prerequisites

- Rocky Linux 9.7 installed on head node
- Root or sudo access
- Network connectivity to compute nodes
- SSH keys already configured (done during virtual cluster setup)
