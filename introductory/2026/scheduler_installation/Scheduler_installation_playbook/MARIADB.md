# MariaDB Manual Setup for Slurm

If the Ansible playbook fails to create the Slurm database automatically, follow these steps to manually set up MariaDB.

## Prerequisites

- MariaDB server must be installed and running
- You must have root access to the database

## Check MariaDB Status

```bash
sudo systemctl status mariadb
```

If not running, start it:
```bash
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

## Method 1: Using sudo (Recommended)

The easiest way on Rocky Linux 9 is to run mysql as root user:

```bash
sudo mysql
```

This should give you a MariaDB prompt without requiring a password (uses socket authentication).

## Method 2: Using Socket Authentication

If sudo doesn't work, connect via the unix socket:

```bash
sudo mysql -S /var/lib/mysql/mysql.sock -u root
```

## Create Database and User

Once connected to MariaDB, run these SQL commands:

```sql
-- Create the accounting database
CREATE DATABASE IF NOT EXISTS slurm_acct_db;

-- Create the slurm user with password
CREATE USER IF NOT EXISTS 'slurm'@'localhost' IDENTIFIED BY 'lcilab2026';

-- Grant privileges
GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- Verify (should show the slurm user)
SELECT User, Host FROM mysql.user WHERE User='slurm';

-- Exit
EXIT;
```

## Verify Database Access

Test that the slurm user can connect:

```bash
mysql -u slurm -p'lcilab2026' -h 127.0.0.1 -D slurm_acct_db -e "SHOW TABLES;"
```

This should show an empty result (no tables yet), which is expected.

## Troubleshooting

### "Access denied for user 'root'@'localhost'"

If you can't connect as root, you may need to reset the root password:

```bash
# Stop MariaDB
sudo systemctl stop mariadb

# Start in safe mode
sudo mysqld_safe --skip-grant-tables &

# Connect without password
mysql -u root

# Reset password
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_new_root_password';
EXIT;

# Restart normally
sudo pkill mysqld
sudo systemctl start mariadb
```

### "Can't connect to local MySQL server"

Check if MariaDB socket exists:
```bash
ls -la /var/lib/mysql/mysql.sock
```

If missing, restart MariaDB:
```bash
sudo systemctl restart mariadb
```

## After Database Setup

Once the database is created, restart the Slurm services:

```bash
sudo systemctl restart slurmdbd
sudo systemctl restart slurmctld
sudo systemctl restart slurmd
```

Verify the services are running:
```bash
sudo systemctl status slurmdbd
sudo systemctl status slurmctld
sudo systemctl status slurmd
```

Test Slurm:
```bash
sinfo
srun hostname
```

## Database Password Reference

The default password used in this setup is: `lcilab2026`

If you used a different password, update `/etc/slurm/slurmdbd.conf`:
```bash
sudo sed -i 's/^StoragePass=.*/StoragePass=your_password/' /etc/slurm/slurmdbd.conf
sudo systemctl restart slurmdbd
```
