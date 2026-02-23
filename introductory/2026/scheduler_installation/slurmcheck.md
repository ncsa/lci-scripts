# Slurm Health Check Commands

## Quick Check: Are All Nodes Reporting?

```bash
sinfo -N -l
```

If both compute nodes show `idle` or `idle*`, everything is running.
If they show `down`, `drain`, or `inval`, see Troubleshooting below.

> **Note:** If `sinfo` doesn't work on the head node but works on compute
> nodes, the Slurm binaries aren't in your PATH. Either source the profile
> or use the full path:
> ```bash
> source /etc/profile.d/slurm.sh
> sinfo -N -l
> ```
> Or:
> ```bash
> /opt/slurm/current/bin/sinfo -N -l
> ```
> This happens because `/etc/profile.d/slurm.sh` only loads on new login
> shells. If you `sudo -i` or open a new SSH session it will be available
> automatically.

## Using ClusterShell (clush) to Verify Services

### Check Slurm daemons on the head node

```bash
clush -g head "systemctl is-active slurmctld slurmdbd"
```

Expected output:
```
lci-head-XX-1: active
lci-head-XX-1: active
```

### Check slurmd on compute nodes

```bash
clush -g compute "systemctl is-active slurmd"
```

Expected output:
```
lci-compute-XX-1: active
lci-compute-XX-2: active
```

### Check munge on all nodes (required by all Slurm daemons)

```bash
clush -g head,compute "systemctl is-active munge"
```

Expected output:
```
lci-head-XX-1: active
lci-compute-XX-1: active
lci-compute-XX-2: active
```

## Detailed Status (with PID, uptime, recent logs)

```bash
clush -g head "systemctl status slurmctld --no-pager -l"
clush -g head "systemctl status slurmdbd --no-pager -l"
clush -g compute "systemctl status slurmd --no-pager -l"
```

## Troubleshooting

If a service shows `inactive` or `failed`:

```bash
# Check the journal for the failing service
clush -g compute "journalctl -xeu slurmd.service --no-pager | tail -20"
clush -g head "journalctl -xeu slurmctld.service --no-pager | tail -20"
clush -g head "journalctl -xeu slurmdbd.service --no-pager | tail -20"
```

### Common Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `sinfo` command not found on head node | Slurm not in PATH | `source /etc/profile.d/slurm.sh` |
| slurmd failed with `libXXX.so not found` | Missing shared library on compute node | `clush -g compute "dnf install -y <package>"` |
| Nodes show `inval` with `Low RealMemory` | slurm.conf RealMemory higher than actual VM memory | See "Fixing inval / Low RealMemory" below |
| Nodes show `down` in sinfo | slurmd not running or hostname mismatch | Check `hostname` matches slurm.conf NodeName |
| slurmdbd won't start | MariaDB not running | `systemctl start mariadb` then `systemctl start slurmdbd` |
| slurmctld won't start | slurmdbd not ready | Wait for slurmdbd, then `systemctl start slurmctld` |

### Fixing inval / Low RealMemory

This happens when `slurm.conf` specifies more `RealMemory` than the VM
actually has available. Slurm is strict — even 1 MB less triggers `inval`.

1. Check actual memory on compute nodes:
   ```bash
   clush -g compute "free -m | grep Mem"
   ```

2. Update `cluster_params.yml` with a value at or below the reported total
   (round down to be safe):
   ```yaml
   mem: '7500'   # adjust to match your VMs
   ```

3. Redeploy slurm.conf and restart:
   ```bash
   ansible-playbook -i hosts.ini playbook.yml
   ```
   Or manually edit `/etc/slurm/slurm.conf` on all nodes (head + compute),
   then:
   ```bash
   systemctl restart slurmctld
   clush -g compute "systemctl restart slurmd"
   ```

4. Resume the nodes:
   ```bash
   scontrol update nodename=lci-compute-01-[1-2] state=resume
   ```

5. Verify:
   ```bash
   sinfo -N -l
   ```
   Nodes should now show `idle`.

## Service Startup Order

If you need to restart everything, follow this order:

```bash
# 1. MariaDB (head node)
systemctl start mariadb

# 2. Munge (all nodes)
clush -g head,compute "systemctl start munge"

# 3. slurmdbd (head node)
systemctl start slurmdbd
# Wait for port 6819
ss -tlnp | grep 6819

# 4. slurmctld (head node)
systemctl start slurmctld
# Wait for port 6817
ss -tlnp | grep 6817

# 5. slurmd (compute nodes)
clush -g compute "systemctl start slurmd"
```
