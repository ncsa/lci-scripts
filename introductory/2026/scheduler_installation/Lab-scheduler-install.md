# Scheduler Installation - Todo List

Replace `01` with your cluster number (e.g., 02, 03, etc.) in all commands and configuration files.

## How to Update Files with Your Cluster Number

### Update hosts.ini:

```bash
cd Scheduler_installation_playbook
vim hosts.ini
:%s/01/<clusternumber>/g
:wq
```

Or using nano:
```bash
nano hosts.ini
# Press Ctrl+\ (search and replace)
# Enter "01" as search term
# Enter your cluster number as replacement
# Press A to replace all occurrences
# Press Ctrl+O to save, then Enter to confirm
# Press Ctrl+X to exit
```

---

## 1. Run Scheduler Installation Playbook

The playbook configures Slurm scheduler on both head node and compute nodes.

```bash
cd ~
cp -a lci-scripts/introductory/2026/scheduler_installation/Scheduler_installation_playbook .
cd Scheduler_installation_playbook
# Edit hosts.ini and replace 01 with your cluster number
ansible-playbook playbook_scheduler.yml
```

Or run specific parts using tags:
```bash
# Configure only the head node
ansible-playbook playbook_scheduler.yml --tags head_node_play

# Configure only compute nodes
ansible-playbook playbook_scheduler.yml --tags compute_node_play
```

---

## 2. Verify Slurm Installation

### On head node:
```bash
systemctl status slurmctld
systemctl status slurmdbd
sinfo
```

### On compute nodes:
```bash
ssh lci-compute-01-1 systemctl status slurmd
ssh lci-compute-01-2 systemctl status slurmd
```

### Test Slurm:
```bash
srun hostname
```

---

## Done!
