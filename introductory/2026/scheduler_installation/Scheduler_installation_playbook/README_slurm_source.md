# Slurm Source Build Playbook

This playbook builds Slurm from source (not RPMs) using the slurm-quickstart approach.

## Quick Start

1. **Navigate to the playbook directory:**
   ```bash
   cd ~/Scheduler_installation_playbook
   ```

2. **Update your hosts and variables if needed:**
   - Edit `hosts.ini` to match your cluster
   - Edit `group_vars/cluster_params.yml` for versions and passwords

3. **Run the playbook:**
   ```bash
   ansible-playbook playbook_slurm_source.yml
   ```

## What This Playbook Does

### Head Node:
1. Installs all build dependencies (same as 01_install_deps)
2. Creates slurm user/group with UID/GID 600 (02_prepare_system)
3. Creates all required directories (/opt/slurm, /etc/slurm, /var/log/slurm, etc.)
4. Initializes MUNGE authentication service
5. Installs and configures MariaDB (03_install_mariadb)
6. Downloads and builds Slurm from source (04_build_slurm)
   - Install location: `/opt/slurm/{{ slurm_vers }}-built/`
   - Symlink: `/opt/slurm/current/`
7. Copies configuration files (slurm.conf, slurmdbd.conf)
8. Installs systemd service files
9. Starts slurmdbd, slurmctld, and slurmd services

### Compute Nodes:
1. Creates slurm user/group
2. Creates required directories
3. Installs munge
4. Syncs entire `/opt/slurm/` directory from head node via rsync
5. Copies munge key from head node
6. Copies slurm.conf
7. Creates `/etc/default/slurmd` with SLURMCTLD_HOST pointing to head node
8. Installs slurmd.service
9. Starts slurmd service

## Troubleshooting

If the build fails:
- Check `/tmp/slurm-{{ slurm_vers }}/build/config.log` for configure errors
- Ensure all dependencies are installed
- Make sure you have enough disk space in /opt

If services don't start:
- Check logs in `/var/log/slurm/`
- Verify MUNGE is running: `systemctl status munge`
- Check slurm.conf syntax: `/opt/slurm/current/bin/slurmd -C`

## Key Differences from RPM Approach

✅ **More reliable** - Builds from source avoids RPM dependency issues
✅ **Consistent** - Uses same approach as slurm-quickstart scripts
✅ **Configurable** - Easy to modify build options in the playbook
✅ **Clean deployment** - Uses rsync to deploy binaries to compute nodes

## Files Location

The configuration files are in:
- `roles/slurm-source/files/slurm.conf`
- `roles/slurm-source/files/slurmdbd.conf`
- `roles/slurm-source/files/*.service`

Edit these if you need to customize Slurm configuration.
