# Lab - Build a Cluster: Head Node

[Click on the link for updated version of the lab on github](https://github.com/ncsa/lci-scripts/tree/main/introductory/head_node/Lab_head_node.md)

**Objective:** Setting up ssh host-based authentication and Ansible cluster management.
Enable Redhat powertools. Configure NFS server for user home directoris.

**Steps:**

- Fixing the host name on the head node.
- Setting ssh host-based authentication.
- Install Ansible and configure Ansible environment for the cluster.
- Use Ansible playbooks to:
  - Install packages.
  - Restart MySQL (Mariadb) for SLURM accounting.
  - Check time synchronization and set time zone.
  - Configure NFS exports for user home directories.

---

### Initial head and compute node bootstrap (what happened first)

- PXE boot from the network: DHCP, tftp services.
- Kernel and ramdisk loaded in the RAM.
- Kickstart installation of OS on the disk.
- Initial system configuration in ks.cfg

---

### Lab cluster environment

This is what we have now:

- Head node and compute nodes already have redhat based operating system:

```bash
cat /etc/redhat-release
```

Rocky Linux release 9.7 (Blue Onyx)

- Base package repositories:

```bash
dnf repolist
```

```text
repo id				 repo name
appstream                        Rocky Linux 9 - AppStream
baseos                           Rocky Linux 9 - BaseOS
crb                              Rocky Linux 9 - CRB
epel                             Extra Packages for Enterprise....
epel-cisco-openh264              Extra Packages for Enterprise....
extras                           Rocky Linux 9 - Extras
```

- Check time zone and synchronization settings:

```bash
timedatectl  status
```

Shows `NTP service: active`

- Passwordless sudo privilege:

```bash
sudo whoami
```

### Hosts in the cluster:

```bash
cat /etc/hosts
```

- Headnode hostname:

```sh
hostname
```

### Fix the head node hostname to match that for the 192.168.45. interface:

```bash
correct_hostname=$(grep lci-head-[0-9][0-9]-1$ /etc/hosts | cut -f 2)
```

It should be lci-head, followed by two numbers.

```bash
echo $correct_hostname
```

Change the hostname:

```bash
sudo hostnamectl set-hostname $correct_hostname
```

## SSH connection to the compute nodes:

- passwordless for root
- needs password for users

### SSH tests

- as rocky

```bash
ssh lci-compute-XX-1
```

- as root

```bash
sudo -i
ssh lci-compute-XX-1
```

---

### Host based SSH authentication setup on the cluster

- **Motivation**

There are three commonly used SSH authentication techniques:

- user name and password
- public/private keys
- host based

Host-based authentication is needed for users to ssh to the compute nodes without password to start MPI computational jobs. An alternative solution would be using the private/public ssh keys, but that would need to be done for every user on the cluster.

- **Configuration files** for the host based authentication:

| **SSH client files:**    | **SSH server files:** |
| ------------------------ | --------------------- |
| /etc/ssh/ssh_config      | /etc/ssh/sshd_config  |
| /etc/ssh/ssh_known_hosts | /etc/hosts.equiv      |

- The following entries need to be added to the configuration files:

/etc/ssh/ssh_config:

```shell
HostbasedAuthentication yes
EnableSSHKeys yes
```

/etc/ssh/sshd_config:

```shell
HostbasedAuthentication yes
IgnoreUserKnownHosts yes
IgnoreRhosts yes
```

/etc/hosts.equiv (maybe different on your cluster):

```shell
192.168.1.88
192.168.1.170
192.168.1.183
192.168.1.177
lci-head-01-1
lci-compute-01-1
lci-compute-01-2
lci-storage-01-1
```

/etc/ssh/ssh_known_hosts (maybe different on your cluster):

```shell
192.168.1.88 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAa2nljkZQEwniXRg/Fm3qf/JBRH68cqdOoftra0oDbVBFGf2YJ53YgZgvD608qN6eCH5hOEEpw5VqHeP1ohjOWv6nT7d2RQ7zp8Pp+bWDfCahC0tpbinb6mnbk75FMHuh6GDBWi9TiMlcPq8jd9uI1RIqtxFnI2j5z2tiTTKlZz2+iNc6UilDdBfXs3ZqMqrG3sAmCbf0T0eSpbCoKYrrG0pGF8QDJi/RI98oJtiL12QpiXupCGKaycT9dU+IxlvD6GHyGcVjR60mXTUzSAqibgrUQkYgZrpyrpGqkuAONylSB4Xdcb/Z1d/kW6MYYk/cZE+DfeV+ezUrQYCGJcQqKzAVQqYVQVANDuGmIQCUK9xKzD6xMkazFjLhkW+nUPBHVghmMDm1uF8CWbbcmzhPjpBoVKwIhePdqaPlRyXS8xa0jeTdCKn83YcF0VpyIzSYVDSTwQIssvQu9EcxXZE5HsB6HdFFdAR9K/DZIiMtecg05or+XjG/lRGLElHV0Pk=
192.168.1.170 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCteJ6VLa+EC60BKEJQ2pqsDfnEE/Rr9+D36Wyc018NF6aXImKhdNA7kDF3e8Nedun/RuoXW/8AWXGfIt/JKJCe3tNUeexYYVq8XEEVpLXMIKdUuPD04oXIvNqCcD4BIXyvebDsFCckLWceplIarRGJwglJRxtYHgh9bQHFXLeIGqRx6YFgwi37VLAQ1klZNZLwnArtBJbYnf0z79hbwxCJ7pugi0eSp1LlUhV733QyGW+J84AmGjxySf4w8+a20GjxUTdJrGngK0OMT8wEkKvmLTL9LnPWGunUOgYai7sJXTbuuhsYJJxSiMFIypoaX5WHUYmYCEkCgsKV6jy0EUX8V6/HJbwlWSLi/g8vhlmiN+Zy2he7WqgT4zFRCJZmv5IHob7pDniTyA9TZiKNAS3xSsz89JEfxqjtupYX2b1aSN5JIpOUrKiiWD+pWaMLAkb37jhfWhy7uPYD585HIYeMB3XC1bfuWa94cfJEsiYnbSt0q90jx2IHG0r4e/b2vy0=

...
```

- We need to deliver these configuration files to the cluster nodes and restart sshd daemon:

```bash
systemctl restart sshd
```

- We'll use Ansible to deliver these files to the nodes and restart ssh service.

Download Ansible playbooks from github.

```bash
git clone https://github.com/ncsa/lci-scripts.git
```

Copy folder SSH_hostbased into your home directory:

```bash
cp -a lci-scripts/introductory/SSH_hostbased .
```

Install package ansible:

```bash
sudo dnf install ansible-core
```

```bash
cd SSH_hostbased
```

Generate file hosts.equiv and ssh_known_hosts by running two shell scripts:

```bash
./gen_hosts_equiv.sh
./ssh_key_scan.sh
```

Fix the compute node hostnames in the inventory files, hosts.ini.

Run the playbook:

```bash
sudo ansible-playbook host_based_ssh.yml
```

Check if you can ssh as user rocky to nodes `lci-compute-xx-1` and `lci-compute-xx-2` without password.

You should be able to ssh between the nodes and elevate privileges to root via sudo.

---

### Setup Ansible

```bash
cd
cp -a lci-scripts/introductory/head_node/Head_node_playbook .
cd Head_node_playbook
```

The Ansible directory contains

- configuration file, ansible.cfg,
- inventory file, hosts.ini,
- playbook playbook.yml,
- directory roles with tasks

The playbook, playbook.yml, calls the roles with various tasks.

---

### Head node package installation

The latest EPEL release release needs to be installed. It can be done with command:

```bash
sudo dnf install epel-release
```

The power tools can be enabled by command

```bash
sudo dnf config-manager --set-enabled powertools
```

We, however, will accomplish these by running Ansible playbooks.

Role `powertools` is taking care of the above tasks.

The following packages need to be installed on the head node:

```shell
ansible
rpm-build
pam-devel
perl
perl-DBI
openssl-devel
readline-devel
mariadb-devel
mariadb-server
python3-PyMySQL
munge-libs
munge-devel
```

These are installed by role `head-node_pkg_inst`.

The same role restarts `mariadb` (MySQL) server.

If done by hand, it would be:

```bash
systemctl restart mariadb
```

### Time set and synchronization

Can be done with two commands:

```bash
timedatectl set-timezone America/Chicago
timedatectl set-ntp yes
```

We have role `timesync` in the Ansible playbook.

---

### NFS server for home directories

Install package nfs-utils can be installed by command dnf:

```bash
sudo dnf install nfs-utils
```

Create export directory:

```bash
mkdir /head/NFS
```

Add entry in file /etc/exports:

```bash
/head/NFS  lci-compute*(rw,async)
```

Restart NFS services:

```bash
systemctl restart nfs-utils
systemctl restart nfs-server
```

The above is accomplished with the tasks in role `head-node_nfs_server`.

---

### Run Ansible playbook

Fix the hostnames of the compute nodes in file hosts.ini

```bash
ansible-playbook playbook.yml
```

Verify that mariadb service is running:

```bash
systemctl status mariadb
```

Verify that the time zone and synchronization, NTP, are set:

```bash
timedatectl  status
```

Verify that the NFS directory is exported:

```bash
showmount -e
```

It should show the exportd directory and the clients.
