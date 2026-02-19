# Head Node Setup - Todo List

Replace `XX` with your cluster number (e.g., 01, 02) in all commands.

## How to Update This File with Your Cluster Number

Using vim:
```bash
vim todo.md
:%s/XX/01/g
:wq
```

Using nano:
```bash
nano todo.md
# Press Ctrl+\ (search and replace)
# Enter "XX" as search term
# Enter "01" (your cluster number) as replacement
# Press A to replace all occurrences
# Press Ctrl+O to save, then Enter to confirm
# Press Ctrl+X to exit
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
sudo dnf install -y ansible-core
```

### On compute nodes:
Edit `Head_node_playbook/hosts.ini` and update hostnames to match your cluster number, then run:
```bash
cd Head_node_playbook
./installansible.sh
```

---

## 3. Run Ansible Playbook

The combined playbook configures both the head node and compute nodes.

```bash
cd ~
cp -a lci-scripts/introductory/head_node/Head_node_playbook .
cd Head_node_playbook
# Edit hosts.ini and replace XX with your cluster number in both [head] and [all_nodes] sections
ansible-playbook playbook.yml
```

### Verify services on head node:
```bash
systemctl status mariadb
timedatectl status
showmount -e
```

### Verify NFS mount on compute nodes:
```bash
ssh lci-compute-XX-1 ls /head/NFS
ssh lci-compute-XX-2 ls /head/NFS
```

---

## 4. Install ClusterShell

```bash
sudo dnf install clustershell
```

Add to `/etc/clustershell/groups.d/local.cfg`:
```
head: lci-head-XX-1
compute: lci-compute-XX-[1-2]
login: lci-head-XX-1
storage: lci-storage-XX-1
```

Test:
```bash
clush -g compute "uptime"
```

---

## 5. Create User Accounts

```bash
sudo useradd -u 2002 justin
sudo useradd -u 2003 katie
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

Add to Modules section:
```
$template DynamicFile,"/var/log/%HOSTNAME%/forwarded-logs.log"
*.* -?DynamicFile
```

Restart:
```bash
sudo systemctl restart rsyslog
```

### On compute and storage nodes:

Add to bottom of `/etc/rsyslog.conf`:
```
*.* @lci-head-XX-1
```

Restart:
```bash
sudo systemctl restart rsyslog
```

### Verify on head node:
```bash
ls /var/log/lci-compute-XX-*/
ls /var/log/lci-storage-XX-*/
```

---

## Done!
