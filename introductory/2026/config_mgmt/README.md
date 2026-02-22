# Configuration Management Tools Lab

This lab introduces three important infrastructure tools for HPC clusters:
- **Ansible**: Agentless configuration management using SSH and YAML
- **Salt (SaltStack)**: Event-driven master-minion automation
- **Warewulf**: HPC cluster bare-metal provisioning system

## Quick Start

```bash
sudo -i
cd ~
git clone https://github.com/ncsa/lci-scripts.git
cp -a lci-scripts/introductory/2026/config_mgmt/Config_mgmt_playbook .
cd Config_mgmt_playbook

# Edit hosts.ini to replace XX with your cluster number
vim hosts.ini
:%s/XX/<clusternumber>/g
:wq

# Run setup
ansible-playbook -i hosts.ini playbook.yml
```

## Lab Files

- `Lab_config_management.md` - Full lab guide with explanations
- `todo.md` - Condensed todo list
- `commands` - Quick reference commands only
- `Config_mgmt_playbook/` - Ansible playbooks for setup
  - `hosts.ini` - Inventory file
  - `ansible.cfg` - Ansible configuration
  - `playbook.yml` - Setup playbook
  - `warewulf.yml` - Warewulf installation playbook
  - `destroy.yml` - Cleanup playbook
  - `roles/` - Ansible roles

## Duration

45-60 minutes

## Prerequisites

- Head Node lab completed (Ansible already installed)
- Working cluster with head node + 2 compute nodes
- Root or sudo access
- Compute nodes with PXE boot capability (for Warewulf)

## What You'll Learn

1. **Ansible** (10 min): Review from Head Node lab, create users, install packages
2. **Salt** (15 min): Install master and minions, create states, use grains
3. **Warewulf** (15 min): Install Warewulf, import images, create overlays, add nodes
4. **Integration** (10-15 min): Use all three tools together for complete workflow

## Architecture

```
Head Node (lci-head-XX-1)
  ├── Ansible Control Node
  ├── Salt Master (port 4505-4506)
  ├── Salt Minion
  └── Warewulf Server (DHCP, TFTP, NFS)

Compute Node 1 (lci-compute-XX-1)
  ├── Salt Minion
  └── Network boot client

Compute Node 2 (lci-compute-XX-2)
  ├── Salt Minion
  └── Network boot client
```

## Tools Comparison

| Tool | Type | When to Use | Best For |
|------|------|-------------|----------|
| Ansible | Agentless (SSH) | Managing running systems | Getting started, deployment |
| Salt | Master-Minion | Event-driven automation | Real-time orchestration |
| Warewulf | Server-Client (PXE) | Bare-metal provisioning | HPC cluster deployment |

## Workflow

**Typical HPC cluster setup:**
1. **Warewulf**: Provision bare-metal nodes with base OS image
2. **Ansible/Salt**: Post-provisioning configuration (Slurm, apps, monitoring)

## Key Concepts

### Ansible
- Playbooks define desired state in YAML
- Inventory defines target nodes
- Idempotent (safe to run multiple times)

### Salt
- Master controls minions via event bus
- States are declarative configuration
- Grains provide system information

### Warewulf
- **Images**: Bootable OS containers (Docker/Podman compatible)
- **Overlays**: Node-specific configuration templates
- **Nodes**: Bare-metal machines to provision
- **Profiles**: Default settings for groups of nodes
- **wwctl**: Control command for all operations

## Important Ports

- **Salt**: 4505-4506 (ZeroMQ)
- **Warewulf**: 67 (DHCP), 69 (TFTP), 111/2049 (NFS)
