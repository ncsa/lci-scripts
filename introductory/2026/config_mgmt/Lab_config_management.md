# Lab: Configuration Management Tools - Ansible, Salt, and Warewulf

## Lab Overview

**Objective:** Learn the basics of Ansible (configuration management), Salt (event-driven automation), and Warewulf (HPC cluster provisioning). Understand their different approaches, use cases, and how they work together.

**Duration:** 45-60 minutes

**Prerequisites:**
- Completed Head Node lab (Ansible already installed and configured)
- Working cluster with head node and 2 compute nodes
- Root or sudo access on head node

**What You Will Learn:**
- **Ansible**: Agentless, YAML-based configuration using SSH
- **Salt**: Master-minion architecture with event-driven automation
- **Warewulf**: HPC cluster provisioning system for bare-metal compute nodes
- How to choose the right tool for different scenarios

---

## Getting Started

### Clone the Repository

```bash
sudo -i
cd ~
git clone https://github.com/ncsa/lci-scripts.git
```

### Copy the Lab Materials

```bash
cp -a lci-scripts/introductory/2026/config_mgmt/Config_mgmt_playbook .
cd Config_mgmt_playbook
```

### Update Configuration

Replace `XX` with your cluster number in all files:

```bash
vim hosts.ini
```

---

## Part 1: Ansible Recap (10 minutes)

You've already used Ansible in the Head Node lab. Let's review the key concepts.

### Key Concepts

- **Agentless**: Uses SSH to connect to nodes
- **Idempotent**: Running the same playbook multiple times produces the same result
- **YAML syntax**: Human-readable configuration files
- **Inventory**: Defines which nodes to manage (`hosts.ini`)
- **Playbooks**: Define the desired state in YAML
- **Roles**: Reusable, modular configuration components

### Quick Review Exercise

View the existing Ansible inventory:

```bash
cat hosts.ini
```

**Output:**
```ini
[head]
lci-head-01-1

[compute]
lci-compute-01-1
lci-compute-01-2

[all_nodes:children]
head
compute
```

Test connectivity:

```bash
ansible all_nodes -i hosts.ini -m ping
```

This uses the `ping` module to verify all nodes are reachable.

### Ansible Ad-Hoc Commands

Ad-hoc commands are one-off commands you can run without writing a playbook.

Check uptime on all nodes:

```bash
ansible all_nodes -i hosts.ini -a "uptime"
```

Check disk space:

```bash
ansible all_nodes -i hosts.ini -a "df -h"
```

Install a package on compute nodes:

```bash
ansible compute -i hosts.ini -m dnf -a "name=htop state=present" --become
```

### Create Your First Ansible Playbook

Create a simple playbook that creates a user on all nodes:

```bash
cat > create_user.yml << 'EOF'
---
- name: Create workshop user on all nodes
  hosts: all_nodes
  become: yes
  tasks:
    - name: Create workshop user
      user:
        name: workshop
        uid: 3000
        state: present
        comment: "Config Management Workshop User"

    - name: Ensure .ssh directory exists
      file:
        path: /home/workshop/.ssh
        state: directory
        owner: workshop
        group: workshop
        mode: '0700'
EOF
```

Run the playbook:

```bash
ansible-playbook -i hosts.ini create_user.yml
```

Verify the user was created:

```bash
ansible all_nodes -i hosts.ini -a "id workshop"
```

**Expected output:**
```
lci-head-01-1 | CHANGED | rc=0 >>
uid=3000(workshop) gid=3000(workshop) groups=3000(workshop)

lci-compute-01-1 | CHANGED | rc=0 >>
uid=3000(workshop) gid=3000(workshop) groups=3000(workshop)

lci-compute-01-2 | CHANGED | rc=0 >>
uid=3000(workshop) gid=3000(workshop) groups=3000(workshop)
```

---

## Part 2: Salt - Master and Minions (15 minutes)

Salt (SaltStack) uses a master-minion architecture with event-driven automation.

### Key Concepts

- **Master-Minion**: Salt master controls Salt minions (agents)
- **Salt States**: Declarative configuration written in YAML (similar to Ansible)
- **Pillar**: Secure data storage for sensitive configuration
- **Grains**: Static data about minions (OS, memory, etc.)
- **Targeting**: Flexible targeting of minions (by name, grain, etc.)

### Install Salt Master on Head Node

```bash
dnf install -y salt-master
```

### Configure Salt Master

Edit the master configuration:

```bash
cat > /etc/salt/master.d/lci.conf << 'EOF'
# Accept all minion keys automatically (for lab only, not production)
auto_accept: True

# Set file roots for state files
file_roots:
  base:
    - /srv/salt

# Set pillar roots
pillar_roots:
  base:
    - /srv/pillar
EOF
```

Create the state file directory:

```bash
mkdir -p /srv/salt
mkdir -p /srv/pillar
```

Start and enable the Salt master:

```bash
systemctl enable --now salt-master
systemctl status salt-master
```

### Install Salt Minion on Compute Nodes

Install on head node (master is also a minion):

```bash
dnf install -y salt-minion
```

Configure the minion to point to the master:

```bash
cat > /etc/salt/minion.d/master.conf << 'EOF'
master: lci-head-01-1
id: lci-head-01-1
EOF
```

Start the minion:

```bash
systemctl enable --now salt-minion
```

Now install and configure minions on compute nodes:

```bash
clush -g compute "dnf install -y salt-minion"
clush -g compute "echo 'master: lci-head-01-1' > /etc/salt/minion.d/master.conf"
clush -g compute "echo 'id: lci-compute-01-1' > /etc/salt/minion.d/id.conf" --host lci-compute-01-1
clush -g compute "echo 'id: lci-compute-01-2' > /etc/salt/minion.d/id.conf" --host lci-compute-01-2
clush -g compute "systemctl enable --now salt-minion"
```

### Verify Minion Connections

List accepted minion keys:

```bash
salt-key -L
```

**Expected output:**
```
Accepted Keys:
lci-head-01-1
lci-compute-01-1
lci-compute-01-2
Denied Keys:
Unaccepted Keys:
Rejected Keys:
```

Test connectivity to all minions:

```bash
salt '*' test.ping
```

### Salt States - Create a User

Create a Salt state file to create the same user we made with Ansible:

```bash
cat > /srv/salt/create_user.sls << 'EOF'
workshop_user:
  user.present:
    - name: workshop_salt
    - uid: 3001
    - fullname: Salt Workshop User

workshop_ssh_dir:
  file.directory:
    - name: /home/workshop_salt/.ssh
    - user: workshop_salt
    - group: workshop_salt
    - mode: 700
    - require:
      - user: workshop_user
EOF
```

Apply the state to all minions:

```bash
salt '*' state.apply create_user
```

Verify the user was created:

```bash
salt '*' cmd.run "id workshop_salt"
```

### Salt Grains - System Information

Grains are static data about minions. View grains on all minions:

```bash
salt '*' grains.items
```

Get specific grain (OS):

```bash
salt '*' grains.get os
```

Target minions by grain (target only Rocky Linux nodes):

```bash
salt -G 'os:Rocky' test.ping
```

### Salt Ad-Hoc Commands (Modules)

Run commands on all minions:

```bash
salt '*' cmd.run "uptime"
```

Install a package:

```bash
salt '*' pkg.install htop
```

Check disk usage:

```bash
salt '*' disk.usage
```

---

## Part 3: Warewulf - HPC Cluster Provisioning (15 minutes)

Warewulf is an HPC cluster provisioning system that deploys operating system images to bare-metal compute nodes via network boot (PXE/iPXE).

### Key Concepts

- **Image (Container)**: A bootable operating system image that will be deployed to compute nodes
- **Overlay**: A collection of files and templates that are rendered per-node and applied over the image
- **Node**: A compute node in the cluster that will be provisioned by Warewulf
- **Profile**: A collection of default settings that can be applied to multiple nodes
- **wwctl**: The Warewulf control command-line tool

### Why Warewulf?

While Ansible and Salt manage configuration on **running** systems, Warewulf:
- Provisions **bare-metal** compute nodes from scratch
- Deploys complete operating system images over the network
- Scales to thousands of nodes
- Integrates with HPC schedulers like Slurm

### Install Warewulf

For this lab, we'll use Ansible to install Warewulf. Run the provided playbook:

```bash
ansible-playbook -i hosts.ini warewulf.yml
```

This playbook will:
1. Install Warewulf server on the head node
2. Configure DHCP, TFTP, and NFS services
3. Set up the Warewulf daemon

### Basic wwctl Commands

Warewulf uses the `wwctl` command for all operations. Let's explore the basics.

#### Check Warewulf Version

```bash
wwctl version
```

#### View Server Configuration

```bash
wwctl server status
```

#### List Available Commands

```bash
wwctl --help
```

**Key wwctl subcommands:**
- `wwctl image` - Manage container images
- `wwctl overlay` - Manage overlays
- `wwctl node` - Manage cluster nodes
- `wwctl profile` - Manage node profiles
- `wwctl configure` - Configure services (DHCP, NFS, etc.)

### Working with Images (Containers)

Warewulf uses container images (similar to Docker/Podman) as the base operating system for compute nodes.

#### Import a Base Image

Import a Rocky Linux 9 image from the Warewulf registry:

```bash
wwctl image import docker://ghcr.io/warewulf/warewulf-rockylinux:9 rockylinux-9
```

**What this does:**
- Downloads the container image from the OCI registry
- Creates a chroot directory at `/var/lib/warewulf/chroots/rockylinux-9/`
- Prepares the image for network boot

#### List Imported Images

```bash
wwctl image list
```

**Expected output:**
```
IMAGE NAME    NODES  KERNEL VERSION      CREATION TIME        MODIFICATION TIME    SIZE
----------    -----  --------------      -------------        -----------------    ----
rockylinux-9  0      5.14.0-362...       Feb 21 10:00 MST     Feb 21 10:00 MST     1.2 GiB
```

See more details:

```bash
wwctl image list --long
```

#### Modify an Image Interactively

Enter the image chroot to make changes:

```bash
wwctl image shell rockylinux-9
```

You'll see a prompt like:
```
[warewulf:rockylinux-9] /#
```

Now you can install packages inside the image:

```bash
[warewulf:rockylinux-9] /# dnf -y install htop vim
```

Exit when done:

```bash
[warewulf:rockylinux-9] /# exit
```

Warewulf will automatically rebuild the image when you exit.

#### Run Commands in an Image (Non-Interactive)

Execute a single command without entering the shell:

```bash
wwctl image exec rockylinux-9 -- /usr/bin/dnf -y install tmux
```

#### Build an Image Manually

If you make changes outside of `wwctl image shell`, rebuild the image:

```bash
wwctl image build rockylinux-9
```

This creates:
- `/var/lib/warewulf/provision/images/rockylinux-9.img` - The uncompressed image
- `/var/lib/warewulf/provision/images/rockylinux-9.img.gz` - The compressed image for network transfer

#### Show Image Details

```bash
wwctl image show rockylinux-9
```

This shows the chroot directory path:
```
/var/lib/warewulf/chroots/rockylinux-9
```

### Working with Overlays

Overlays are collections of files and templates that are rendered per-node and applied over the base image during provisioning. They're used for node-specific configuration.

#### List Available Overlays

```bash
wwctl overlay list
```

**Expected output:**
```
OVERLAY NAME     FILES/DIRS  SITE
------------     ----------  ----
wwinit           10          false
wwclient         2           false
fstab            2           false
hostname         1           false
ssh.host_keys    2           false
ssh.authorized_keys  1       false
hosts            1           false
issue            1           false
...
```

**Key distribution overlays:**
- **wwinit**: Initial configuration during boot
- **wwclient**: Periodically updates runtime configuration
- **fstab**: Configures /etc/fstab for NFS mounts
- **hostname**: Sets the node hostname
- **ssh.host_keys**: Distributes SSH host keys
- **hosts**: Configures /etc/hosts with all nodes

#### List Files in an Overlay

```bash
wwctl overlay list --all wwinit
```

#### Create a Custom Overlay

Create a new overlay for site-specific configuration:

```bash
wwctl overlay create site-custom
```

Add a file to the overlay:

```bash
wwctl overlay import site-custom /etc/motd --parents
```

Edit the file (make it a template):

```bash
wwctl overlay edit site-custom /etc/motd
```

Add some content:
```
Welcome to {{.Id}}
This node is part of the LCI 2026 workshop cluster.
Managed by Warewulf v4
```

#### Show Overlay Content

```bash
wwctl overlay show site-custom /etc/motd
```

#### Render an Overlay Template for a Specific Node

```bash
wwctl overlay show site-custom /etc/motd --render n1
```

This shows how the template will be rendered with actual node values.

#### Build Overlays

Build all overlays for all nodes:

```bash
wwctl overlay build
```

Build for a specific node:

```bash
wwctl overlay build n1
```

### Working with Nodes

#### Add a Cluster Node

Add a compute node to Warewulf:

```bash
wwctl node add lci-compute-01-1 \
  --ipaddr=10.0.2.1 \
  --hwaddr=00:00:00:00:00:01 \
  --image=rockylinux-9
```

Add the second compute node:

```bash
wwctl node add lci-compute-01-2 \
  --ipaddr=10.0.2.2 \
  --hwaddr=00:00:00:00:00:02 \
  --image=rockylinux-9
```

**Note:** Replace the hardware addresses (MAC addresses) with the actual MAC addresses of your compute nodes.

#### List Nodes

```bash
wwctl node list
```

See all details:

```bash
wwctl node list --all
```

#### Set Node Properties

Configure a node's image:

```bash
wwctl node set lci-compute-01-1 --image=rockylinux-9
```

Add overlays to a node:

```bash
wwctl node set lci-compute-01-1 \
  --system-overlays="wwinit,wwclient,fstab,hostname,ssh.host_keys,site-custom" \
  --runtime-overlays="hosts,ssh.authorized_keys"
```

#### Enable Node Discovery

If you don't know the MAC address yet, enable discovery:

```bash
wwctl node set lci-compute-01-1 --discoverable=true
```

When the node first boots and requests an image, Warewulf will capture its MAC address.

### Working with Profiles

Profiles are collections of default settings applied to multiple nodes.

#### List Profiles

```bash
wwctl profile list
```

#### Create a Profile

```bash
wwctl profile add lci-compute \
  --image=rockylinux-9 \
  --system-overlays="wwinit,wwclient,fstab,hostname,ssh.host_keys,site-custom"
```

#### Set Profile Properties

Configure NFS mounts for all nodes in the profile:

```bash
wwctl profile set lci-compute \
  --resource=fstab='[{"spec":"lci-head-01-1:/home","file":"/home","vfstype":"nfs","mntops":"defaults"}]'
```

### Configure Supporting Services

Warewulf can configure DHCP, NFS, and other services:

#### Configure DHCP

```bash
wwctl configure dhcp
```

This updates `/etc/dhcp/dhcpd.conf` with node entries.

#### Configure NFS

```bash
wwctl configure nfs
```

This updates `/etc/exports` with Warewulf directories.

#### Configure SSH

```bash
wwctl configure ssh
```

This sets up SSH keys for root access to nodes.

### Comparison: Ansible/Salt vs Warewulf

| Feature | Ansible/Salt | Warewulf |
|---------|--------------|----------|
| **When to use** | Managing running systems | Provisioning bare-metal nodes |
| **Target** | Existing OS | Empty/blank machines |
| **Deployment** | SSH/Agent | Network boot (PXE/iPXE) |
| **Image** | None (incremental changes) | Complete OS image |
| **Persistence** | Configuration on disk | Stateless or persistent |

**Typical HPC workflow:**
1. **Warewulf**: Provision bare-metal nodes with base OS
2. **Ansible/Salt**: Post-provisioning configuration (Slurm, apps, etc.)

---

## Part 4: Comparison and Best Practices (10-15 minutes)

Now that you've used all three tools, let's compare them.

### Side-by-Side Comparison

| Feature | Ansible | Salt | Warewulf |
|---------|---------|------|----------|
| **Architecture** | Agentless (SSH) | Master-Minion | Server-Client (PXE) |
| **Syntax** | YAML | YAML | CLI commands |
| **Learning Curve** | Low | Medium | Low-Medium |
| **Scalability** | Good (10K+ nodes) | Excellent (50K+ nodes) | Excellent (10K+ nodes) |
| **Push vs Pull** | Push (on-demand) | Both | Pull (at boot) |
| **Target State** | Running systems | Running systems | Bare-metal nodes |
| **Use Case** | Configuration, deployment | Event-driven, real-time | OS provisioning |

### When to Use Each Tool

**Ansible:**
- Great for: Provisioning, application deployment, ad-hoc tasks
- Best when: You need to get started quickly, have existing SSH infrastructure
- Example use cases: Bootstrapping new servers, deploying applications, running maintenance tasks

**Salt:**
- Great for: Event-driven automation, real-time orchestration, large-scale cloud
- Best when: You need speed and real-time responses
- Example use cases: Auto-scaling cloud instances, continuous configuration, complex orchestration

**Warewulf:**
- Great for: HPC cluster provisioning, bare-metal deployment
- Best when: You need to provision many identical compute nodes
- Example use cases: HPC clusters, compute farms, stateless compute nodes

### Practical Exercise: Configure All Tools Together

Let's use all three tools together to configure a complete environment:

**Step 1: Use Warewulf to import a base image**

```bash
wwctl image import docker://ghcr.io/warewulf/warewulf-rockylinux:9 rockylinux-9
```

**Step 2: Use Ansible to add nodes to Warewulf**

Create a playbook:

```bash
cat > setup_nodes.yml << 'EOF'
---
- name: Configure Warewulf nodes
  hosts: head
  become: yes
  tasks:
    - name: Add compute nodes to Warewulf
      command: |
        wwctl node add {{ item.name }} \
          --ipaddr={{ item.ip }} \
          --image=rockylinux-9 \
          --discoverable=true
      loop:
        - { name: 'lci-compute-01-1', ip: '10.0.2.1' }
        - { name: 'lci-compute-01-2', ip: '10.0.2.2' }
      ignore_errors: yes

    - name: Configure DHCP
      command: wwctl configure dhcp

    - name: Build overlays
      command: wwctl overlay build
EOF

ansible-playbook -i hosts.ini setup_nodes.yml
```

**Step 3: Use Salt to manage post-provisioning configuration**

Create a Salt state for Slurm client configuration:

```bash
cat > /srv/salt/slurm_client.sls << 'EOF'
slurm_packages:
  pkg.installed:
    - pkgs:
      - slurm
      - slurm-slurmd

slurmd_service:
  service.running:
    - name: slurmd
    - enable: True
    - require:
      - pkg: slurm_packages

slurm_config:
  file.managed:
    - name: /etc/slurm/slurm.conf
    - source: salt://files/slurm.conf
    - require:
      - pkg: slurm_packages
EOF
```

Apply to compute nodes:

```bash
salt 'lci-compute-*' state.apply slurm_client
```

### Cleanup

Remove the test users:

```bash
# Remove with Ansible
ansible all_nodes -i hosts.ini -m user -a "name=workshop state=absent remove=yes" --become

# Remove with Salt
salt '*' user.absent workshop_salt remove=True

# Remove Warewulf nodes
wwctl node delete lci-compute-01-1
wwctl node delete lci-compute-01-2
```

---

## Summary

You've now used three important HPC infrastructure tools:

1. **Ansible**: Agentless, simple YAML, great for configuration management
2. **Salt**: Master-minion, event-driven, excellent for real-time orchestration  
3. **Warewulf**: HPC provisioning system for bare-metal compute nodes

### Key Takeaways

- **Ansible** is the easiest to learn and requires no agents - perfect for general configuration
- **Salt** offers the best performance and real-time capabilities - great for dynamic environments
- **Warewulf** provisions bare-metal HPC nodes efficiently - essential for HPC clusters
- All three can work together: Warewulf for provisioning, Ansible/Salt for post-boot configuration
- Choose based on your specific needs: deployment speed, real-time requirements, infrastructure type

### Further Learning

- **Ansible**: Read about Ansible Galaxy (sharing roles), Ansible Tower/AWX (enterprise features)
- **Salt**: Explore Salt Cloud (provisioning), Salt Beacons (monitoring)
- **Warewulf**: Learn about image templates, custom overlays, and integration with Slurm

---

## Troubleshooting

### Ansible Issues

**Problem**: "Permission denied" when running playbooks
**Solution**: Use `--ask-become-pass` or ensure passwordless sudo is configured

**Problem**: SSH connection failures
**Solution**: Verify SSH keys are distributed: `ansible all_nodes -i hosts.ini -m ping`

### Salt Issues

**Problem**: Minion cannot connect to master
**Solution**: Check firewall (port 4505-4506) and verify minion configuration:
```bash
salt-minion -l debug
```

**Problem**: State application fails
**Solution**: Check state syntax and view detailed output:
```bash
salt '*' state.apply state_name -l debug
```

### Warewulf Issues

**Problem**: Image import fails
**Solution**: Check internet connectivity and Docker registry access:
```bash
wwctl image import docker://ghcr.io/warewulf/warewulf-rockylinux:9 rockylinux-9 --debug
```

**Problem**: Nodes won't boot
**Solution**: Check DHCP and TFTP configuration:
```bash
wwctl configure dhcp
wwctl configure tftp
systemctl status dhcpd
systemctl status tftp
```

**Problem**: Overlays not applying
**Solution**: Rebuild overlays:
```bash
wwctl overlay build
```

**Problem**: Can't shell into image
**Solution**: Check that the image exists and is not corrupted:
```bash
wwctl image list
wwctl image build rockylinux-9
```

---

*End of Lab*
