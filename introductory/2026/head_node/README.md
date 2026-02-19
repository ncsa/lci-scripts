# Head Node Lab

This directory contains materials for the Head Node configuration lab of the LCI Introductory Workshop.

## Files Overview

### `Lab_head_node.md`
The comprehensive lab guide that walks students through the entire head node setup process. This is the main instructional document and includes:
- Initial cluster environment verification
- Hostname configuration
- SSH host-based authentication setup
- Ansible playbook execution for automated configuration
- Manual service configuration steps (clustershell, user accounts, central logging)
- Quick reference commands at the end for post-playbook configuration

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

## Workflow

1. **Read `Lab_head_node.md`** - Follow the complete lab instructions from start to finish
2. **Run the Head_node_playbook** - Execute automated configuration: `ansible-playbook Head_node_playbook/playbook.yml`
3. **Execute quick reference commands** - Complete manual configuration steps from the "Quick Reference Commands" section at the end of Lab_head_node.md
4. **Verify setup** - Confirm all services are running correctly

## Prerequisites

- Rocky Linux 9.7 installed on head node
- Root or sudo access
- Network connectivity to compute nodes
- SSH keys already configured (done during virtual cluster setup)
