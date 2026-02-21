# Slurm Troubleshooting Guide

When Slurm services fail to start, follow these steps to diagnose and fix the issue.

## Quick Diagnostic Commands

Run these commands to identify the problem:

```bash
# Check service status
sudo systemctl status slurmctld
sudo systemctl status slurmdbd
sudo systemctl status slurmd

# View detailed error logs
sudo journalctl -xeu slurmd.service --no-pager -n 50
sudo journalctl -xeu slurmctld.service --no-pager -n 50
sudo journalctl -xeu slurmdbd.service --no-pager -n 50

# Check Slurm logs
cat /var/log/slurm/slurmctld.log
cat /var/log/slurm/slurmd.log
cat /var/log/slurm/slurmdbd.log
```

---

## Common Issues and Fixes

### 1. Hostname Mismatch

**Symptom:** slurmd fails with "unable to determine this host's hostname"

**Check:**
```bash
hostname
hostname -s
grep SlurmctldHost /etc/slurm/slurm.conf
grep NodeName /etc/slurm/slurm.conf
```

**Fix:**
```bash
# Set hostname to match slurm.conf
sudo hostnamectl set-hostname lci-head-XX-1

# Or edit /etc/slurm/slurm.conf to match current hostname
sudo vim /etc/slurm/slurm.conf
# Update SlurmctldHost and NodeName lines
```

---

### 2. Permission Issues

**Symptom:** "Permission denied" errors in logs

**Check:**
```bash
ls -la /var/spool/slurmd.spool/
ls -la /var/log/slurm/
ls -la /var/run/slurm/
ls -la /etc/slurm/
```

**Fix:**
```bash
# Fix ownership
sudo chown -R slurm:slurm /var/spool/slurmd.spool
sudo chown -R slurm:slurm /var/log/slurm
sudo chown -R slurm:slurm /var/run/slurm
sudo chown -R slurm:slurm /etc/slurm

# Fix permissions
sudo chmod 755 /var/spool/slurmd.spool
sudo chmod 644 /etc/slurm/slurm.conf
sudo chmod 600 /etc/slurm/slurmdbd.conf
```

---

### 3. Missing Directories

**Symptom:** "No such file or directory" errors

**Fix:**
```bash
# Create missing directories
sudo mkdir -p /var/spool/slurmd.spool
sudo mkdir -p /var/spool/slurm.state
sudo mkdir -p /var/log/slurm
sudo mkdir -p /var/run/slurm
sudo mkdir -p /etc/slurm

# Set ownership
sudo chown -R slurm:slurm /var/spool/slurmd.spool
sudo chown -R slurm:slurm /var/spool/slurm.state
sudo chown -R slurm:slurm /var/log/slurm
sudo chown -R slurm:slurm /var/run/slurm
sudo chown -R slurm:slurm /etc/slurm
```

---

### 4. MUNGE Authentication Failure

**Symptom:** "authentication failure" or "munge decode" errors

**Check:**
```bash
# Test MUNGE
munge -n | unmunge

# Check MUNGE service
sudo systemctl status munge

# Verify key exists
ls -la /etc/munge/munge.key
```

**Fix:**
```bash
# Restart MUNGE
sudo systemctl restart munge

# If key is missing, regenerate
sudo create-munge-key
sudo systemctl restart munge

# On compute nodes, copy key from head
sudo rsync -av root@lci-head-XX-1:/etc/munge/munge.key /etc/munge/
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
sudo systemctl restart munge
```

---

### 5. Configuration Syntax Errors

**Symptom:** "fatal: Unable to process configuration file"

**Check:**
```bash
# Validate slurm.conf
sudo /opt/slurm/current/bin/slurmctld -D -v -f /etc/slurm/slurm.conf 2>&1 | head -20

# Check for syntax errors
sudo /opt/slurm/current/bin/slurmd -C
```

**Fix:**
```bash
# Edit and fix configuration
sudo vim /etc/slurm/slurm.conf

# Common issues:
# - Missing or incorrect SlurmctldHost
# - NodeName doesn't match hostname
# - Missing required parameters
```

---

### 6. Port Already in Use

**Symptom:** "Address already in use" errors

**Check:**
```bash
# Check ports
sudo ss -tlnp | grep 6817  # slurmctld
sudo ss -tlnp | grep 6818  # slurmd
sudo ss -tlnp | grep 6819  # slurmdbd
```

**Fix:**
```bash
# Kill existing processes
sudo pkill -f slurmctld
sudo pkill -f slurmd
sudo pkill -f slurmdbd

# Restart services
sudo systemctl restart slurmctld
sudo systemctl restart slurmdbd
sudo systemctl restart slurmd
```

---

### 7. Database Connection Issues (slurmdbd)

**Symptom:** slurmdbd fails to start

**Check:**
```bash
# Test database connection
mysql -u slurm -p'lcilab2026' -h 127.0.0.1 -D slurm_acct_db -e "SHOW TABLES;"

# Check MariaDB status
sudo systemctl status mariadb
```

**Fix:**
```bash
# If database doesn't exist, create it
sudo mysql <<'EOF'
CREATE DATABASE IF NOT EXISTS slurm_acct_db;
CREATE USER IF NOT EXISTS 'slurm'@'localhost' IDENTIFIED BY 'lcilab2026';
GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';
FLUSH PRIVILEGES;
EOF

# Restart slurmdbd
sudo systemctl restart slurmdbd
```

---

### 8. Library Path Issues

**Symptom:** "error while loading shared libraries"

**Fix:**
```bash
# Update library cache
sudo ldconfig

# Verify Slurm libraries are registered
cat /etc/ld.so.conf.d/slurm.conf

# If missing, add it
echo "/opt/slurm/current/lib64" | sudo tee /etc/ld.so.conf.d/slurm.conf
sudo ldconfig
```

---

## Complete Reset Procedure

If all else fails, do a complete reset:

```bash
# 1. Stop all services
sudo systemctl stop slurmd slurmctld slurmdbd munge

# 2. Clean up state
sudo rm -rf /var/spool/slurm.state/*
sudo rm -rf /var/spool/slurmd.spool/*

# 3. Fix permissions
sudo chown -R slurm:slurm /var/spool/slurmd.spool
sudo chown -R slurm:slurm /var/spool/slurm.state
sudo chown -R slurm:slurm /var/log/slurm
sudo chown -R slurm:slurm /var/run/slurm
sudo chown -R slurm:slurm /etc/slurm

# 4. Start in correct order
sudo systemctl start munge
sudo systemctl start slurmdbd
sleep 5
sudo systemctl start slurmctld
sleep 5
sudo systemctl start slurmd

# 5. Verify
sudo systemctl status slurmctld slurmdbd slurmd
sinfo
```

---

## Verification Commands

After fixing, verify everything works:

```bash
# Check all services are running
sudo systemctl status slurmctld slurmdbd slurmd

# Check cluster status
sinfo

# Test job submission
srun hostname

# Check accounting
sacct
```

---

## Getting Help

If issues persist:

1. Check the full log:
   ```bash
   sudo journalctl -u slurmd.service --since "1 hour ago"
   ```

2. Run in debug mode:
   ```bash
   sudo /opt/slurm/current/sbin/slurmd -D -v 2>&1
   ```

3. Check SchedMD documentation:
   - https://slurm.schedmd.com/troubleshoot.html
