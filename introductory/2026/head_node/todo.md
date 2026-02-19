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

## 2. Run Head Node Ansible Playbook

```bash
cd ~
cp -a lci-scripts/introductory/head_node/Head_node_playbook .
cd Head_node_playbook
# Edit hosts.ini and replace XX with your cluster number
ansible-playbook playbook.yml
```

### Verify services:
```bash
systemctl status mariadb
timedatectl status
showmount -e
```

---

## 3. Install ClusterShell

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

## 4. Create User Accounts

```bash
sudo useradd -u 2002 justin
sudo useradd -u 2003 katie
```

---

## 5. Configure Central Logging

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
