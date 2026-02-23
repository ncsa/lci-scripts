# Lab - Build a Cluster: Head Node

> **Quick Start:** For a condensed list of commands only, see [`todo.md`](todo.md) in this directory.

## Lab Overview

**Objective:** This lab guides you through configuring the head node of an HPC cluster, including setting up Ansible for automated configuration management, installing ClusterShell for parallel command execution, configuring NFS for shared storage, and setting up centralized logging.

**Prerequisites:**
- Rocky Linux 9.7 installed on head node and compute nodes
- Root or sudo access
- Network connectivity between head node and compute nodes
- SSH host-based authentication already configured (done during virtual cluster setup)

**What You Will Learn:**
- How to properly configure hostnames in a cluster environment
- How to use Ansible playbooks for automated system configuration
- How to set up NFS server for shared filesystems
- How to install and configure ClusterShell for managing multiple nodes
- How to create and propagate user groups across cluster nodes
- How to create and propagate user accounts with consistent UIDs across the cluster
- How to configure centralized logging with rsyslog

---

## Getting Started: Update Configuration Files

Before beginning, you need to customize the configuration files for your specific cluster. All commands and configuration files use `XX` as a placeholder for your cluster number (e.g., if you're assigned cluster 01, replace all instances of `XX` with `01`).

### Using vim to Replace Placeholders:

```bash
vim todo.md
:%s/01/<clusternumber>/g
:wq
```

This vim command:
- `:%s` - Starts a substitution command across the entire file
- `01` - The pattern to search for (replace with your actual cluster number if different)
- `<clusternumber>` - Your assigned cluster number (e.g., 02, 03, etc.)
- `g` - Replace all occurrences globally in the file
- `:wq` - Save and quit

### Switch to Root User

All commands in this lab require root privileges. Switch to root with:

```bash
sudo -i
cd
```

The `sudo -i` command opens an interactive root shell, and `cd` ensures you're in root's home directory.

### Download the Lab Scripts

```bash
git clone https://github.com/ncsa/lci-scripts.git
```

This downloads the repository containing Ansible playbooks, configuration templates, and helper scripts needed for the lab.

---

## Section 1: Fix Hostname

### Why This Matters

In an HPC cluster, consistent hostnames are critical for:
- Service discovery (nodes need to find each other by name)
- Slurm scheduler operation (uses hostnames to identify resources)
- NFS mounting (clients mount using server hostnames)
- Logging and monitoring (identifies which node generated logs)

In OpenStack environments, VMs often get assigned hostnames with domain suffixes like `.novalocal` which can cause issues with cluster services.

### Check Current Hostname

```bash
hostname
```

**Expected Output:**
```text
lci-head-01-1.novalocal
```

The `.novalocal` suffix is automatically added by OpenStack and can cause connectivity issues with cluster services.

### Find the Correct Hostname

```bash
correct_hostname=$(grep lci-head-[0-9][0-9]-1$ /etc/hosts | cut -f 2)
```

**What this does:**
- Searches `/etc/hosts` for a line ending with the pattern `lci-head-XX-1`
- Extracts the second field (the hostname) from that line
- Stores it in the `correct_hostname` variable

### Verify the Variable

```bash
echo $correct_hostname
```

**Expected Output:**
```text
lci-head-01-1
```

This should show the hostname without the `.novalocal` suffix.

### Apply the Hostname Change

```bash
hostnamectl set-hostname $correct_hostname
```

This uses systemd's hostnamectl to permanently set the hostname. The change takes effect immediately without requiring a reboot.

### Verify the Change

```bash
hostname
```

**Expected Output:**
```text
lci-head-01-1
```

The hostname should now match what's in `/etc/hosts` without any domain suffix.

---

## Section 2: Install Ansible

### What is Ansible?

Ansible is an open-source automation tool that allows you to:
- Configure multiple systems simultaneously
- Deploy applications and services
- Orchestrate complex IT workflows
- Maintain configuration consistency across your cluster

Ansible uses a "push" model where the head node (control node) connects to managed nodes via SSH and executes tasks defined in playbooks.

### Install Ansible on the Head Node

```bash
dnf install -y ansible-core
```

**What this installs:**
- `ansible-core` - The minimal Ansible installation with core functionality
- Python dependencies required for Ansible modules
- SSH client tools for connecting to managed nodes

**Why just the head node?** 
The head node acts as the Ansible control node. Compute nodes don't need Ansible installed unless they will also act as control nodes (which they won't in this setup).

---

## Section 3: Configure Cluster with Ansible Playbook

### Overview

This step uses a combined Ansible playbook that configures:
1. **Head Node:** Repositories, packages (MariaDB, NFS server), time synchronization
2. **Compute Nodes:** NFS client (autofs), time synchronization, common packages

The playbook uses SSH to connect to compute nodes and apply configurations automatically.

### Step-by-Step Process

#### 1. Copy the Playbook to Your Home Directory

```bash
cd ~
cp -a lci-scripts/introductory/2026/head_node/Head_node_playbook .
```

The `cp -a` command preserves permissions and directory structure.

#### 2. Navigate to the Playbook Directory

```bash
cd Head_node_playbook
```

#### 3. Edit the Inventory File

```bash
vim hosts.ini
```

Replace `XX` with your cluster number in both the `[head]` and `[all_nodes]` sections:

**Original:**
```ini
[all_nodes]
lci-compute-XX-1
lci-compute-XX-2

[head]
localhost ansible_connection=local
```

**After editing (for cluster 01):**
```ini
[all_nodes]
lci-compute-01-1
lci-compute-01-2

[head]
localhost ansible_connection=local
```

**Explanation:**
- `[all_nodes]` - Group containing all compute nodes
- `[head]` - Group containing the head node (localhost with local connection)
- `ansible_connection=local` - Tells Ansible to run head node tasks locally without SSH

#### 4. Install Ansible on Compute Nodes

```bash
bash installansible.sh
```

This script:
- Reads the hostnames from `hosts.ini`
- Uses SSH to connect to each compute node
- Installs `ansible-core` on each node
- Required because some Slurm components need Ansible

#### 5. Run the Playbook

```bash
ansible-playbook playbook.yml
```

This executes the playbook which:
- Configures repositories (EPEL, CRB)
- Installs packages (MariaDB, NFS utilities, development tools)
- Configures time synchronization
- Sets up NFS server on head node and NFS client (autofs) on compute nodes
- Starts and enables required services

**Playbook Structure:**
- **Play 1 (head node):** Runs locally, configures repositories, installs packages, sets up NFS server
- **Play 2 (compute nodes):** Runs via SSH, installs packages, configures autofs for NFS mounting

### Verify the Configuration

After the playbook completes, verify the services are running:

```bash
systemctl status mariadb
```

MariaDB should be active (running). This is the database that will store Slurm accounting data.

```bash
timedatectl status
```

Should show correct timezone (America/Chicago) and NTP service active.

```bash
showmount -e
```

Lists NFS exports. Should show `/head/NFS` exported to compute nodes.

### Test NFS Connectivity

Create a test file on the head node:

```bash
touch /head/NFS/testfile
```

Verify it appears on compute nodes:

```bash
ssh lci-compute-XX-1 ls /head/NFS
ssh lci-compute-XX-2 ls /head/NFS
```

Both should list `testfile`, confirming NFS is working.

---

## Section 4: Install ClusterShell

### What is ClusterShell?

ClusterShell is a Python-based library and set of tools for executing commands across multiple Linux nodes in parallel. It provides:
- **clush** - Run commands on multiple nodes simultaneously
- **cluset** - Node set management (define groups of nodes)
- **clubak** - Collect and display output from multiple nodes

### Why Use ClusterShell?

In HPC cluster administration, you frequently need to:
- Check status on all compute nodes
- Distribute files across the cluster
- Monitor resource usage
- Perform maintenance tasks

Without ClusterShell, you would need to SSH to each node individually. With ClusterShell, you can run one command that executes on all nodes.

### Installation

```bash
dnf install -y clustershell
```

This installs:
- The ClusterShell Python library
- Command-line tools (clush, cluset, clubak)
- Default configuration files

### Configure Node Groups

Edit the ClusterShell groups file:

```bash
vim /etc/clustershell/groups.d/local.cfg
```

Remove any existing uncommented content and add:

```text
head: lci-head-XX-1
compute: lci-compute-XX-[1-2]
login: lci-head-XX-1
storage: lci-storage-XX-1
```

**Group Definitions:**
- `head` - The head/login node
- `compute` - All compute nodes (uses range notation [1-2] to match compute-01-1 and compute-01-2)
- `login` - Alias for head node (users log in here)
- `storage` - The storage node

**Replace XX with your cluster number!**

### Test ClusterShell

Run a simple command across all compute nodes:

```bash
clush -g compute "uptime"
```

**Expected Output:**
```text
---------------
lci-compute-01-1 (1)
---------------
 12:30:00 up 2 days, 4:15, 0 users, load average: 0.02, 0.05, 0.01
---------------
lci-compute-01-2 (1)
---------------
 12:30:00 up 2 days, 4:15, 0 users, load average: 0.01, 0.03, 0.00
```

This shows the uptime from both compute nodes simultaneously.

**Other Useful clush Commands:**

Check disk space on all nodes:
```bash
clush -g compute "df -h"
```

Check memory usage:
```bash
clush -g compute "free -h"
```

Run commands on specific nodes:
```bash
clush -w lci-compute-01-1 "hostname"
```

### Fix Hostnames on Compute and Storage Nodes

Just as the head node may have a `.novalocal` suffix, the compute and storage nodes likely do as well. Use ClusterShell to fix all of them at once:

```bash
# Fix hostnames on compute nodes
clush -g compute 'correct_hostname=$(grep $(hostname -s) /etc/hosts | grep lci-compute | head -1 | awk "{print \$2}"); sudo hostnamectl set-hostname $correct_hostname'
```

**What this does:**
- Gets the short hostname from the current hostname
- Searches `/etc/hosts` for a matching entry with `lci-compute` in it
- Extracts the correct hostname from the second column
- Uses `hostnamectl` to set the hostname without the `.novalocal` suffix
- Runs in parallel on all compute nodes

```bash
# Fix hostname on storage node
clush -g storage 'correct_hostname=$(grep $(hostname -s) /etc/hosts | grep lci-storage | head -1 | awk "{print \$2}"); sudo hostnamectl set-hostname $correct_hostname'
```

**What this does:**
- Same process as above, but for the storage node
- Ensures storage node hostname is also cleaned up

```bash
# Verify hostnames are fixed on all nodes
clush -g compute,storage "hostname"
```

**Expected Output:**
```text
---------------
lci-compute-01-1 (1)
---------------
lci-compute-01-1
---------------
lci-compute-01-2 (1)
---------------
lci-compute-01-2
---------------
lci-storage-01-1 (1)
---------------
lci-storage-01-1
```

All hostnames should now be clean without any `.novalocal` suffix.

---

## Section 5: Create Groups and User Accounts Across All Nodes

### Why Create These Groups and Accounts?

For the workshop exercises, we need:
- **Two groups** (`lci-bio` and `lci-eng`) representing different research groups
- **Two user accounts** (`justin` and `katie`) that:
  - Are consistent across all cluster nodes with matching UIDs/GIDs
  - Allow running MPI and Slurm jobs across multiple nodes
  - Demonstrate proper user/group management in HPC environments
  - `justin` is assigned to the `lci-bio` group (biology researchers)
  - `katie` is assigned to the `lci-eng` group (engineering researchers)

Without consistent UIDs/GIDs across the cluster, jobs running on multiple nodes would encounter permission errors and file ownership issues.

### Step 1: Create Groups on Head Node

First, create two groups representing different research departments:

```bash
groupadd -g 3001 lci-bio
groupadd -g 3002 lci-eng
```

**What this does:**
- Creates `lci-bio` group with GID 3001 (for biology researchers)
- Creates `lci-eng` group with GID 3002 (for engineering researchers)
- Establishes consistent group identifiers for cluster-wide use

### Step 2: Create Users on Head Node

Create the two user accounts, each assigned to a different research group:

```bash
useradd -u 2002 -g lci-bio justin
useradd -u 2003 -g lci-eng katie
```

**What this does:**
- Creates `justin` with UID 2002 and primary group `lci-bio` (biology research group)
- Creates `katie` with UID 2003 and primary group `lci-eng` (engineering research group)
- Creates home directories in `/home/`
- Sets up default shell (bash) and environment

### Step 3: Propagate Groups to All Compute Nodes

Use ClusterShell to create the same groups on all compute nodes:

```bash
clush -g compute "groupadd -g 3001 lci-bio"
clush -g compute "groupadd -g 3002 lci-eng"
```

**What this does:**
- Executes `groupadd` commands in parallel on all compute nodes
- Ensures consistent GIDs (3001 and 3002) across the cluster
- Required for proper file permissions when users run jobs on compute nodes

### Step 4: Propagate Users to All Compute Nodes

Use ClusterShell to create the same users on all compute nodes:

```bash
clush -g compute "useradd -u 2002 -g lci-bio justin"
clush -g compute "useradd -u 2003 -g lci-eng katie"
```

**What this does:**
- Creates `justin` (UID 2002) with `lci-bio` group and `katie` (UID 2003) with `lci-eng` group on all compute nodes
- Ensures users have identical UIDs and primary groups across the cluster
- Enables seamless job execution across multiple nodes

### Step 5: Verify Groups and Users Across the Cluster

Verify groups exist on all nodes:

```bash
clush -g all "getent group lci-bio"
clush -g all "getent group lci-eng"
```

**Expected Output:**
```text
---------------
lci-head-01-1 (1)
---------------
lci-bio:x:3001:justin
---------------
lci-compute-01-1 (1)
---------------
lci-bio:x:3001:justin
---------------
lci-compute-01-2 (1)
---------------
lci-bio:x:3001:justin
---------------
lci-head-01-1 (1)
---------------
lci-eng:x:3002:katie
---------------
lci-compute-01-1 (1)
---------------
lci-eng:x:3002:katie
---------------
lci-compute-01-2 (1)
---------------
lci-eng:x:3002:katie
```

Verify users exist on all nodes:

```bash
clush -g all "id justin"
clush -g all "id katie"
```

**Expected Output:**
```text
---------------
lci-head-01-1 (1)
---------------
uid=2002(justin) gid=3001(lci-bio) groups=3001(lci-bio)
---------------
lci-compute-01-1 (1)
---------------
uid=2002(justin) gid=3001(lci-bio) groups=3001(lci-bio)
---------------
lci-compute-01-2 (1)
---------------
uid=2002(justin) gid=3001(lci-bio) groups=3001(lci-bio)
---------------
lci-head-01-1 (1)
---------------
uid=2003(katie) gid=3002(lci-eng) groups=3002(lci-eng)
---------------
lci-compute-01-1 (1)
---------------
uid=2003(katie) gid=3002(lci-eng) groups=3002(lci-eng)
---------------
lci-compute-01-2 (1)
---------------
uid=2003(katie) gid=3002(lci-eng) groups=3002(lci-eng)
```

**Note:** In a production environment, user accounts would be managed through LDAP or Active Directory for consistency across all nodes. For this workshop, we're using ClusterShell to propagate them manually.

---

## Section 6: Configure Central Logging

### Why Centralized Logging?

In an HPC cluster with many nodes:
- Each node generates logs (system, Slurm, application)
- Checking logs on each node individually is impractical
- Centralized logging allows monitoring the entire cluster from one location
- Essential for debugging job failures and system issues

We'll configure rsyslog to forward logs from compute and storage nodes to the head node.

### Configure Head Node (Log Collector)

Edit the rsyslog configuration:

```bash
vim /etc/rsyslog.conf
```

#### Step 1: Uncomment UDP/TCP Input Modules

Find these lines (around line 15-20) and uncomment them:

```
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp")
input(type="imtcp" port="514")
```

**What this does:**
- Enables rsyslog to receive log messages via UDP and TCP
- Port 514 is the standard syslog port
- Compute nodes will send logs to this port

#### Step 2: Add Log Routing Configuration

Find the `### Modules ###` section and add at the end:

```
$template DynamicFile,"/var/log/%HOSTNAME%/forwarded-logs.log"
*.* -?DynamicFile
```

**What this does:**
- Creates a template named `DynamicFile`
- `%HOSTNAME%` will be replaced with the sending node's hostname
- Creates separate log files for each host in `/var/log/<hostname>/`
- `*.*` means all logs from all facilities and priorities
- `-?` means use the template and don't sync after every write (better performance)

#### Step 3: Restart rsyslog

```bash
systemctl restart rsyslog
```

This applies the configuration changes.

### Configure Compute and Storage Nodes (Log Forwarders)

On each compute node and the storage node, edit `/etc/rsyslog.conf`:

```bash
vim /etc/rsyslog.conf
```

Add to the bottom of the file:

```
*.* @lci-head-XX-1
```

**Replace XX with your cluster number!**

**What this does:**
- `*.*` - Forward all logs (all facilities, all priorities)
- `@` - Use UDP for forwarding (use `@@` for TCP)
- `lci-head-XX-1` - The destination (head node)

Restart rsyslog on each node:

```bash
systemctl restart rsyslog
```

### Verify Centralized Logging

Wait a few minutes for logs to be generated and forwarded, then check on the head node:

```bash
ls /var/log/lci-compute-XX-*/
ls /var/log/lci-storage-XX-*/
```

You should see directories for each compute and storage node containing their forwarded logs.

Check the actual log files:

```bash
cat /var/log/lci-compute-XX-1/forwarded-logs.log
```

This should show system logs from that compute node.

---

## Lab Completion

Congratulations! You have successfully:

✅ Configured the head node hostname  
✅ Installed and configured Ansible  
✅ Used Ansible playbooks to configure head and compute nodes  
✅ Set up NFS server for shared storage  
✅ Installed ClusterShell for cluster management  
✅ Created user groups (`lci-bio`, `lci-eng`) representing research departments across all nodes  
✅ Created user accounts (`justin` in lci-bio, `katie` in lci-eng) with consistent UIDs across all nodes  
✅ Configured centralized logging across the cluster  

### Next Steps

Your cluster is now ready for the next labs:
- Scheduler installation (Slurm)
- Running applications via the scheduler
- OpenMP and MPI programming

### Troubleshooting Tips

**Issue: NFS mount not working on compute nodes**
- Check: `showmount -e` on head node
- Check: `systemctl status nfs-server` on head node
- Check: `systemctl status autofs` on compute nodes
- Check: `df -h | grep head` on compute nodes

**Issue: ClusterShell can't connect to nodes**
- Verify: `ssh lci-compute-XX-1 hostname` works
- Check: `/etc/clustershell/groups.d/local.cfg` has correct hostnames
- Verify: Host-based SSH authentication is working

**Issue: Logs not appearing on head node**
- Check: Firewall rules (port 514 UDP/TCP)
- Verify: `systemctl status rsyslog` on all nodes
- Check: Network connectivity between nodes

---

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [ClusterShell Documentation](https://clustershell.readthedocs.io/)
- [NFS Documentation](https://docs.nfsv4.org/)
- [rsyslog Documentation](https://www.rsyslog.com/doc/)
