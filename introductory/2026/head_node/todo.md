# Head Node Setup - Todo List

## How to Update This File with Your Cluster Number
Replace `XX` with your cluster number (e.g., 02, 03, etc.) in all commands and configuration files.

Using vim:
```bash
vim todo.md
:%s/01/<clusternumber>/g
:wq
```
## run the below comamands as root
```bash
sudo -i
cd
```

## Pull the lci-scipts repository to get the playbook and other scripts:

```bash
git clone https://github.com/ncsa/lci-scripts.git
``` 

---

## 1. Fix Hostname

```bash
correct_hostname=$(grep lci-head-[0-9][0-9]-1$ /etc/hosts | cut -f 2)
sudo hostnamectl set-hostname $correct_hostname
```

---

## 2. Install Ansible

### On the head node:
```bash
dnf install -y ansible-core
```

---

## 3. Install ansible on compute nodes and Run Ansible Playbook

The combined playbook configures both the head node and compute nodes.

```bash
cd ~
cp -a lci-scripts/introductory/2026/scheduler_installation/Scheduler_installation_playbook .
cd Scheduler_installation_playbook
# Edit hosts.ini and replace XX with your cluster number in both [head] and [all_nodes] sections
bash installansible.sh
ansible-playbook playbook.yml
```

### Verify services on head node:
```bash
systemctl status mariadb
timedatectl status
showmount -e
```
### Create file in /head/NFS on head node and verify it is visible on compute nodes:
```bash
touch /head/NFS/testfile
ssh lci-compute-XX-1 ls /head/NFS
ssh lci-compute-XX-2 ls /head/NFS
```

---

## 4. Install ClusterShell - to run commands on multiple nodes at once.

```bash
dnf install -y clustershell
```

### Edit `/etc/clustershell/groups.d/local.cfg` remove everything uncommented and add:
```text
head: lci-head-XX-1
compute: lci-compute-XX-[1-2]
login: lci-head-XX-1
storage: lci-storage-XX-1
```

Test:
```bash
clush -g compute "uptime"
```

### Fix hostnames on compute and storage nodes (remove .novalocal suffix):
```bash
# Fix hostnames on compute nodes
clush -g compute 'correct_hostname=$(grep $(hostname -s) /etc/hosts | grep lci-compute | head -1 | awk "{print \$2}"); sudo hostnamectl set-hostname $correct_hostname'

# Fix hostname on storage node
clush -g storage 'correct_hostname=$(grep $(hostname -s) /etc/hosts | grep lci-storage | head -1 | awk "{print \$2}"); sudo hostnamectl set-hostname $correct_hostname'

# Verify hostnames are fixed
clush -g compute,storage "hostname"
```

---

## 5. Create Groups and User Accounts Across All Nodes

### Create groups on head node:
```bash
groupadd -g 3001 lci-bio
groupadd -g 3002 lci-eng
```

### Create users on head node (justin in lci-bio, katie in lci-eng):
```bash
useradd -u 2002 -g lci-bio justin
useradd -u 2003 -g lci-eng katie
```

### Propagate groups to compute and storage nodes:
```bash
clush -g compute,storage "groupadd -g 3001 lci-bio"
clush -g compute,storage "groupadd -g 3002 lci-eng"
```

### Propagate users to compute and storage nodes:
```bash
clush -g compute,storage "useradd -u 2002 -g lci-bio justin"
clush -g compute,storage "useradd -u 2003 -g lci-eng katie"
```

### Verify across compute and storage nodes:
```bash
clush -g compute,storage "getent group lci-bio"
clush -g compute,storage "getent group lci-eng"
clush -g compute,storage "id justin"
clush -g compute,storage "id katie"
```

---

## 6. Configure Central Logging

### On head node (lci-head-XX-1):

Edit `/etc/rsyslog.conf`, uncomment:
```
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp")
input(type="imtcp" port="514")
```

Add to the end of '### Modules ###' section:
```
$template DynamicFile,"/var/log/%HOSTNAME%/forwarded-logs.log"
*.* -?DynamicFile
```

Restart:
```bash
systemctl restart rsyslog
```

### On compute and storage nodes:

Add to bottom of `/etc/rsyslog.conf`:
```
*.* @lci-head-XX-1
```

Restart:
```bash
systemctl restart rsyslog
```

### Verify on head node:
```bash
ls /var/log/lci-compute-XX-*/
ls /var/log/lci-storage-XX-*/
```

---

## Done!
