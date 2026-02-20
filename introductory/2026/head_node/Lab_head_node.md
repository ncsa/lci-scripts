# Lab - Build a Cluster: Head Node

> **Quick Start:** For a condensed list of commands only, see [`todo.md`](todo.md) in this directory.

**Objective:** Setting up ssh host-based authentication and Ansible cluster management.
Enable Redhat powertools. Configure NFS server for user home directoris.

**Steps:**

- Fixing the host name on the head node.
- Setting ssh host-based authentication.
- Install Parallel Shell and configure for the cluster
- Configure central logging
- Install Ansible and configure Ansible environment for the cluster.
- Use Ansible playbooks to:
  - Install packages.
  - Restart MySQL (Mariadb) for SLURM accounting.
  - Check time synchronization and set time zone.
  - Configure NFS exports for user home directories.

---

## Quick Reference Commands

The following commands can be executed after running the Ansible playbook to complete additional cluster configuration. Save these to a file and customize for your cluster.

**First: Replace XX with your cluster number (e.g., 01, 02, etc.)**

Using vim:
```bash
vim commands
:%s/XX/01/g
:wq
```

Pull the lci-scipts repository to get the playbook and other scripts:

```bash
git clone https://github.com/ncsa/lci-scripts.git
``` 
---

### Lab cluster environment

This is what we have to start:

Head node and compute nodes already have redhat based operating system:<br>
- To verify, run the following command:
```bash
cat /etc/redhat-release
```
expected output should be something like:
```text
Rocky Linux release 9.7 (Blue Onyx)
```

- Base package repositories:
```bash
dnf repolist
```

```text
repo id                          repo name
appstream                        Rocky Linux 9 - AppStream
baseos                           Rocky Linux 9 - BaseOS
crb                              Rocky Linux 9 - CRB
epel                             Extra Packages for Enterprise Linux 9 - x86_64
epel-cisco-openh264              Extra Packages for Enterprise Linux 9 openh264 (From Cisco) - x86_64
extras                           Rocky Linux 9 - Extras
```

- Check time zone and synchronization settings:

```bash
timedatectl  status
```
- expected output should show correct time zone and that NTP service is active. For example, it might say `Time zone: America/Chicago (CDT, -0500)` and `NTP service: active`.
```text                                                                                                                                                                                                                                                                                                                                                                                    
               Local time: Fri 2026-02-20 12:22:04 CST                                                                                                                                                                                   
           Universal time: Fri 2026-02-20 18:22:04 UTC                                                                                                                                                                                   
                 RTC time: Fri 2026-02-20 18:22:04                                                                                                                                                                                       
                Time zone: America/Chicago (CST, -0600)                                                                                                                                                                                  
System clock synchronized: yes                                                                                                                                                                                                           
              NTP service: active                                                                                                                                                                                                        
          RTC in local TZ: no 
```

### 01. Hosts in the cluster:

```bash
cat /etc/hosts
```
- expected output on lci-head-01-1 (names will be different for your cluster):
```text
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4                                                                                                                                                           
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6                                                                                                                                                           
                                                                                                                                                                                                                                         
141.142.221.155 lci-head-01-1.ncsa.cloud                                                                                                                                                                                                 
192.168.1.25    lci-head-01-1                                                                                                                                                                                                            
192.168.1.181   lci-compute-01-1                                                                                                                                                                                                         
192.168.1.176   lci-compute-01-2                                                                                                                                                                                                         
192.168.1.254   lci-storage-01-1 
```

### 02. Fix the head node hostname to match that for the 192.168.45. interface:

Current hostname:
```bash
hostname
```
- expected output on lci-head-01-1 (names will be different for your cluster):
```text
lci-head-01-1.novalocal
```

To change hostname, we need to find the correct one from the /etc/hosts file. The correct hostname should be lci-head, followed by two numbers, then -1.
```bash
correct_hostname=$(grep lci-head-[0-9][0-9]-1$ /etc/hosts | cut -f 2)
```

Now check that the hostname we have in the variable is correct:
```bash
echo $correct_hostname
```
```text
lci-head-01-1
```

Change the hostname:
```bash
sudo hostnamectl set-hostname $correct_hostname
```
Verify the change:
```bash
hostname
```
```text
lci-head-01-1
```
---

## 03. Install Ansible

### On the head node:

Install ansible-core:

```bash
sudo dnf install -y ansible-core
```

### On compute nodes (as rocky):

Edit `Head_node_playbook/hosts.ini` and update the hostnames to match your cluster number (e.g., change `XX` 
to your actual cluster number), then run the install script:

```bash
cd Head_node_playbook
sudo bash installansible.sh
```

This script will install ansible-core on all compute nodes listed in the hosts.ini file.

## 04. SSH connection to the compute nodes:

- passwordless for root
- needs password for users

### SSH tests

As rocky
```bash
ssh lci-compute-XX-1
```
  - shouldn't work

As root
```bash
sudo -i
ssh lci-compute-XX-1
```
- works - which is why we are working as root

---

### 05. Install Parallel Shell
- On your head node for this section - run as root
- **Note:** Replace `XX` with your cluster number (e.g., `01`, `02`) in all commands below.

```bash
dnf install clustershell
```

Add the following to the `/etc/clustershell/groups.d/local.cfg` file (replace the example stuff):
```
head: lci-head-XX-1
compute: lci-compute-XX-[1-2]
login: lci-head-XX-1
storage: lci-storage-XX-1
```

Test it out:
```bash
clush -g compute "uptime"
```

### 06. Create User Accounts

```bash
useradd -u 2002 justin
useradd -u 2003 katie
```

### 07. Configure Central Logging

On the head node (`lci-head-XX-1`), edit `/etc/rsyslog.conf` and uncomment the following lines:

```bash
module(load="imudp") # needs to be done just once
input(type="imudp" port="514")

module(load="imtcp") # needs to be done just once
input(type="imtcp" port="514")
```

Add these two lines in the Modules section:
```bash
$template DynamicFile,"/var/log/%HOSTNAME%/forwarded-logs.log"
*.* -?DynamicFile
```

Restart rsyslog on the head node:
```bash
systemctl restart rsyslog
```

On both compute nodes and the storage node, add the following to the very bottom of `/etc/rsyslog.conf`:
```bash
*.* @lci-head-XX-1
```

Then restart rsyslog on those nodes:
```bash
systemctl restart rsyslog
```

After a few minutes you should see new log directories in `/var/log/` on `lci-head-XX-1`, with a directory for each host forwarding logs:
```bash
ls /var/log/lci-[computes/storage]-XX-Y/
```