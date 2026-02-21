# MariaDB Root Authentication Fix (Rocky Linux 9.7)

## The Problem

On Rocky Linux 9.7, MariaDB defaults to `unix_socket` authentication for the root user. This means the OS root user can connect with just `mysql` (no password needed). However, if `mysql_secure_installation` was previously run, or a prior playbook set a root password, the auth plugin gets changed to `mysql_native_password`. After that, `mysql` without a password fails with:

```
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
```

This blocks the playbook from creating the `slurm_acct_db` database and `slurm` database user.

## How the Playbook Handles It

The v2 playbook (`playbook-slurm-source-v2.yml`) includes an automatic repair sequence:

1. **Tests connectivity** -- runs `mysql -e "SELECT 1;"` as the OS root user
2. **If the test passes** -- skips the repair entirely, proceeds to database setup
3. **If the test fails** -- runs the repair block:
   - Stops MariaDB
   - Restarts with `--skip-grant-tables --skip-networking` (allows unauthenticated local access, no network exposure)
   - Runs `ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket` to restore passwordless auth
   - Shuts down the skip-grant-tables instance
   - Restarts MariaDB normally
   - Verifies root can now connect
4. **Proceeds** with creating the slurm database and user

This is fully idempotent -- on subsequent runs, the connectivity test passes and the repair block is skipped.

## Manual Fix (If the Playbook Repair Fails)

If the automatic repair doesn't work, follow these steps manually on the head node as root.

### Step 1: Stop MariaDB

```bash
systemctl stop mariadb
```

### Step 2: Start MariaDB in unsafe mode

This starts MariaDB without authentication checks and with networking disabled (safe from remote access):

```bash
mysqld_safe --skip-grant-tables --skip-networking &
```

Wait a few seconds for it to start, then verify:

```bash
mysql -e "SELECT 1;"
```

You should see `1` printed with no errors.

### Step 3: Reset root to unix_socket auth

```bash
mysql -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket; FLUSH PRIVILEGES;"
```

### Step 4: Shut down the unsafe instance

```bash
mysqladmin shutdown
```

Wait for it to fully stop:

```bash
while [ -e /var/lib/mysql/mysql.sock ]; do sleep 1; done
```

### Step 5: Start MariaDB normally

```bash
systemctl start mariadb
systemctl enable mariadb
```

### Step 6: Verify

```bash
mysql -e "SELECT 1;"
```

This should return `1` with no password prompt and no errors.

### Step 7: Create the Slurm database (if not already done)

```bash
mysql <<'EOF'
CREATE DATABASE IF NOT EXISTS slurm_acct_db;
CREATE USER IF NOT EXISTS 'slurm'@'localhost' IDENTIFIED BY 'lcilab2026';
GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';
FLUSH PRIVILEGES;
EOF
```

Verify the database and user exist:

```bash
mysql -e "SHOW DATABASES;" | grep slurm_acct_db
mysql -e "SELECT user, host, plugin FROM mysql.user WHERE user='slurm';"
```

### Step 8: Re-run the playbook

After the manual fix, re-run the playbook. It will skip past the MariaDB repair (since root now works) and continue with the rest of the installation:

```bash
ansible-playbook -i hosts.ini playbook-slurm-source-v2.yml -vv
```

## Preventing the Problem in the First Place

If you are starting from a completely fresh MariaDB installation, do **not** run `mysql_secure_installation`. The playbook handles database security by:

- Creating a dedicated `slurm` user with a password for database access
- Slurm daemons connect as the `slurm` DB user, never as root
- The `slurmdbd.conf` file (mode 0600, owned by slurm:slurm) stores the DB password

If you need to secure MariaDB root beyond unix_socket auth (e.g., to set a root password for remote access), do so only **after** the playbook has completed successfully.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `mysql -e "SELECT 1;"` | Test if root can connect |
| `mysql -e "SELECT user, host, plugin FROM mysql.user WHERE user='root';"` | Check root auth plugin |
| `mysql -e "SHOW DATABASES;"` | List databases |
| `mysql -e "SELECT user, host FROM mysql.user;"` | List all database users |
| `systemctl status mariadb` | Check MariaDB service status |
| `journalctl -u mariadb -n 50` | View recent MariaDB logs |
