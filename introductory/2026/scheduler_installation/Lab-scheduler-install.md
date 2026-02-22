# Scheduler Installation - Todo List

Replace `01` with your cluster number (e.g., 02, 03, etc.) in all commands and configuration files.

## 1. Copy Playbook and Update Configuration

```bash
cd ~
cp -a lci-scripts/introductory/2026/scheduler_installation/Scheduler_installation_playbook .
cd Scheduler_installation_playbook
```

### Update hosts.ini:

```bash
vim hosts.ini
:%s/01/<clusternumber>/g
:wq
```

### Update group_vars/cluster_params.yml:

```bash
vim group_vars/cluster_params.yml
```

Change the cluster number:
```yaml
# From:
cluster_number: 01
# To:
cluster_number: <your_cluster_number>
```

Save and exit: `:wq`

---

## 2. Run Scheduler Installation Playbook

The playbook builds Slurm from source on the head node and deploys it to all compute nodes.

```bash
ansible-playbook -i hosts.ini playbook.yml
```

**Note:** This playbook does not use tags. It always configures both head node and compute nodes.

---

## 3. Destroy / Cleanup (if needed)

To completely remove Slurm and start fresh:

```bash
ansible-playbook -i hosts.ini destroy.yml
```

---

## 4. Verify Slurm Installation

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
