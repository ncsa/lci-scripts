# Slurm Source Build Playbook (v2)

Automated installation of Slurm from source on Rocky Linux 9.7 clusters using Ansible.

## Cluster Layout

Each student cluster consists of three nodes:

| Role | Hostname | Description |
|------|----------|-------------|
| Head node | `lci-head-XX-1` | Runs slurmctld, slurmdbd, MariaDB, and also acts as a compute node |
| Compute node 1 | `lci-compute-XX-1` | Runs slurmd |
| Compute node 2 | `lci-compute-XX-2` | Runs slurmd |

`XX` is your assigned cluster number (01-40).

## Prerequisites

- SSH access from the head node to both compute nodes (password-less or via ssh-agent)
- Rocky Linux 9.7 on all nodes
- `/etc/hosts` configured on all nodes so hostnames resolve correctly
- `/etc/hostname` set correctly on the head node
- Internet access on the head node (to download the Slurm source tarball)
- Run the playbook **from the head node** as a user with sudo privileges

## Student Setup (3 Steps)

### Step 1: Edit `hosts.ini`

Replace every occurrence of `01` with your assigned cluster number.

For example, if you are assigned cluster **14**, change the file to:

```ini
[all_nodes]
lci-compute-14-1
lci-compute-14-2

[head]
lci-head-14-1 ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

> **Important:** Keep `ansible_connection=local` and `ansible_python_interpreter=/usr/bin/python3` on the `[head]` line. Only change the hostname.

### Step 2: Edit `group_vars/cluster_params.yml`

Change `cluster_number` to your assigned number:

```yaml
cluster_number: '14'
```

Everything else in the file is derived automatically. Do not modify the lines below the comment `# --- Derived / common settings ---`.

### Step 3: Run the Playbook

From the `Scheduler_installation_playbook/` directory on your head node:

```bash
ansible-playbook -i hosts.ini playbook-slurm-source-v2.yml
```

If you need to see more verbose output, add `-v` (or `-vv` / `-vvv` for even more detail):

```bash
ansible-playbook -i hosts.ini playbook-slurm-source-v2.yml -vv
```

## What the Playbook Does

### Head Node Play

1. **Installs build dependencies** -- munge, development libraries, compilers
2. **Creates the slurm user/group** -- UID/GID 600
3. **Creates directories** -- `/opt/slurm`, `/etc/slurm`, `/var/log/slurm`, spool directories
4. **Pre-creates log files** -- `slurmdbd.log`, `slurmctld.log`, `slurmd.log` with correct ownership
5. **Configures MUNGE** -- generates key, sets permissions, starts the service
6. **Installs and configures MariaDB** -- creates the `slurm_acct_db` database and `slurm` DB user
7. **Downloads, builds, and installs Slurm** from source into `/opt/slurm/<version>-built/`
8. **Creates a symlink** `/opt/slurm/current` pointing to the installed version
9. **Registers Slurm libraries** with `ldconfig` so shared libraries are found
10. **Deploys configuration files** -- `slurm.conf`, `slurmdbd.conf`, `job_container.conf` (all from templates)
11. **Copies systemd service files** -- `slurmdbd.service`, `slurmctld.service`, `slurmrestd.service`, `slurmd.service`
12. **Starts services in order** -- slurmdbd, slurmctld, slurmd

### Compute Node Play

1. **Creates the slurm user/group** (matching UID/GID 600)
2. **Creates directories** on compute nodes
3. **Installs MUNGE** and copies the key from the head node
4. **Syncs the Slurm installation** (`/opt/slurm/`) from the head node via rsync
5. **Registers Slurm libraries** with `ldconfig`
6. **Deploys `slurm.conf`** from the same template
7. **Copies the `slurmd.service`** unit and configures configless mode (points to head node)
8. **Starts slurmd** after confirming slurmctld is reachable

## Verifying the Installation

After the playbook completes, run these commands on the head node:

```bash
# Check that all nodes are reporting
/opt/slurm/current/bin/sinfo

# Check the cluster is registered
/opt/slurm/current/bin/sacctmgr show cluster

# Submit a test job
/opt/slurm/current/bin/srun -N1 hostname

# Check service status
systemctl status slurmctld
systemctl status slurmdbd
systemctl status slurmd
```

## Troubleshooting

### Playbook fails at MariaDB tasks

If the database tasks fail, verify MariaDB is running:

```bash
systemctl status mariadb
```

Then test that root can connect (as the OS root user):

```bash
sudo mysql -e "SELECT 1;"
```

On Rocky 9.7, MariaDB uses `unix_socket` authentication by default, so the `mysql` command must be run as root (no `-u root` flag needed).

### slurmd fails to start on head node

Check that the service file exists and systemd knows about it:

```bash
ls -la /etc/systemd/system/slurmd.service
systemctl daemon-reload
systemctl status slurmd
journalctl -u slurmd -n 50
```

### Compute nodes cannot reach slurmctld

Verify the head node hostname resolves from the compute node:

```bash
# From a compute node
ping lci-head-XX-1
```

Check that port 6817 is open:

```bash
ss -tlnp | grep 6817
```

### slurmd fails on compute nodes with library errors

Verify `ldconfig` has been run and Slurm libraries are registered:

```bash
ldconfig -p | grep slurm
```

If empty, run:

```bash
echo "/opt/slurm/current/lib64" > /etc/ld.so.conf.d/slurm.conf
ldconfig
```

## File Reference

| File | Purpose |
|------|---------|
| `playbook-slurm-source-v2.yml` | Main playbook |
| `hosts.ini` | Ansible inventory (student edits this) |
| `group_vars/cluster_params.yml` | Cluster variables (student edits `cluster_number`) |
| `roles/slurm-source/templates/slurm.conf.j2` | Slurm configuration template |
| `roles/slurm-source/templates/slurmdbd.conf.j2` | Slurm database daemon config template |
| `roles/slurm-source/templates/slurmd_defaults.j2` | Environment file for slurmd (configless mode) |
| `roles/slurm-source/files/slurmctld.service` | systemd unit for slurmctld |
| `roles/slurm-source/files/slurmdbd.service` | systemd unit for slurmdbd |
| `roles/slurm-source/files/slurmd.service` | systemd unit for slurmd |
| `roles/slurm-source/files/slurmrestd.service` | systemd unit for slurmrestd |

## Tearing Down

To completely remove Slurm and start fresh, use the destroy playbook:

```bash
ansible-playbook -i hosts.ini destroy_slurm_complete.yml
```
