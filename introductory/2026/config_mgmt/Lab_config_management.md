# Lab: Configuration Management Tools - Ansible and Salt

## Lab Overview

**Objective:** Learn the basics of Ansible (configuration management) and Salt (event-driven automation). Understand their different approaches, use cases, and how they can work together to manage an HPC cluster.

**Duration:** 45-60 minutes

**Prerequisites:**
- Completed Head Node lab (Ansible already installed and configured)
- Working cluster with head node and 2 compute nodes
- Root or sudo access on head node

**What You Will Learn:**
- **Ansible**: Agentless, YAML-based configuration using SSH
- **Salt**: Master-minion architecture with event-driven automation
- How to use Ansible and Salt together effectively
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

Replace `XX` with your cluster number in `hosts.ini`:

**Using vim:**
```bash
vim hosts.ini
# In vim, type:  :%s/XX/<clusternumber>/g
# Then save:     :wq
```

**Using nano:**
```bash
nano hosts.ini
# Press Ctrl+\, Enter "XX", Enter your cluster number, A, Ctrl+O, Enter, Ctrl+X
```

---

## Part 1: Ansible Recap (15 minutes)

You've already used Ansible in the Head Node lab. Let's review the key concepts and explore more features.

### Key Concepts

- **Agentless**: Uses SSH to connect to nodes
- **Idempotent**: Running the same playbook multiple times produces the same result
- **YAML syntax**: Human-readable configuration files
- **Inventory**: Defines which nodes to manage (`hosts.ini`)
- **Playbooks**: Define the desired state in YAML
- **Modules**: Pre-built tools for common tasks (dnf, copy, user, etc.)

### Quick Review Exercise

View the existing Ansible inventory:

```bash
cat hosts.ini
```

**Output:**
```ini
[head]
lci-head-XX-1 ansible_connection=local

[compute]
lci-compute-XX-1
lci-compute-XX-2

[all_nodes:children]
head
compute
```

Note: `ansible_connection=local` tells Ansible to run commands locally on the head node instead of SSHing to itself.

### Test Connectivity

```bash
ansible all_nodes -i hosts.ini -m ping
```

This uses the `ping` module to verify all nodes are reachable.

### Ansible Ad-Hoc Commands - Gathering Information

Ad-hoc commands are one-off commands you can run without writing a playbook.

Check uptime on all nodes:

```bash
ansible all_nodes -i hosts.ini -a "uptime"
```

Check disk space:

```bash
ansible all_nodes -i hosts.ini -a "df -h"
```

Check hostnames:

```bash
ansible all_nodes -i hosts.ini -a "hostname"
```

Get OS information:

```bash
ansible all_nodes -i hosts.ini -m shell -a "cat /etc/os-release | head -2"
```

### Ansible Ad-Hoc Commands - Using Modules

Query system memory using the `setup` module:

```bash
ansible all_nodes -i hosts.ini -m setup -a "filter=ansible_memory_mb"
```

Install packages on compute nodes:

```bash
ansible compute -i hosts.ini -m dnf -a "name=htop state=present" --become
ansible compute -i hosts.ini -m dnf -a "name=tmux state=present" --become
```
### essentially "Go to my compute nodes and make sure the tmux/htop program is installed."


Verify packages installed:

```bash
ansible compute -i hosts.ini -m shell -a "rpm -q htop tmux"
```

### Copy a File to All Nodes

Use the `copy` module to distribute a file:

```bash
ansible all_nodes -i hosts.ini -m copy -a "content='Hello from LCI 2026\n' dest=/tmp/lci_test.txt" --become
ansible all_nodes -i hosts.ini -a "cat /tmp/lci_test.txt"
```

### Create Your First Ansible Playbook

Using your preferred editor (vim or nano), create a file called `create_user.yml` with the following content:

```yaml
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
lci-head-XX-1 | CHANGED | rc=0 >>
uid=3000(workshop) gid=3000(workshop) groups=3000(workshop)

lci-compute-XX-1 | CHANGED | rc=0 >>
uid=3000(workshop) gid=3000(workshop) groups=3000(workshop)

lci-compute-XX-2 | CHANGED | rc=0 >>
uid=3000(workshop) gid=3000(workshop) groups=3000(workshop)
```

### Install Salt via Ansible

Run the included playbook to install Salt on all nodes (used in Part 2):

```bash
ansible-playbook -i hosts.ini playbook.yml
```

This demonstrates Ansible's strength as a deployment tool - using it to bootstrap another configuration management system.

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
auto_accept: True
file_roots:
  base:
    - /srv/salt
pillar_roots:
  base:
    - /srv/pillar
EOF
```

Create the state file directories:

```bash
mkdir -p /srv/salt /srv/pillar
```

Start and enable the Salt master:

```bash
systemctl enable --now salt-master
```

### Install Salt Minion on Head Node

```bash
dnf install -y salt-minion
```

Using your preferred editor (vim or nano), create `/etc/salt/minion.d/master.conf`. The file should contain the following two lines:

```
master: lci-head-XX-1
id: lci-head-XX-1
```

```bash
vim /etc/salt/minion.d/master.conf
```

Start the minion:

```bash
systemctl enable --now salt-minion
```

### Install Salt Minion on Compute Nodes

```bash
clush -g compute "dnf install -y salt-minion"
clush -g compute "echo 'master: lci-head-XX-1' > /etc/salt/minion.d/master.conf"
clush -w lci-compute-XX-1 "echo 'id: lci-compute-XX-1' > /etc/salt/minion.d/id.conf"
clush -w lci-compute-XX-2 "echo 'id: lci-compute-XX-2' > /etc/salt/minion.d/id.conf"
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
lci-head-XX-1
lci-compute-XX-1
lci-compute-XX-2
Denied Keys:
Unaccepted Keys:
Rejected Keys:
```

Test connectivity to all minions:

```bash
salt '*' test.ping
```

### Salt States - Create a User

Create a Salt state file to create a user (similar to what we did with Ansible):

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

## Part 3: Warewulf - HPC Cluster Provisioning (Reference Only)

> **Note:** This section is provided as reference material. Warewulf requires bare-metal or properly networked clusters and cannot be run on the virtual workshop clusters.

Warewulf is an HPC cluster provisioning system that deploys operating system images to bare-metal compute nodes via network boot (PXE/iPXE).

### Key Concepts

- **Image (Container)**: A bootable operating system image deployed to compute nodes
- **Overlay**: Files and templates rendered per-node and applied over the image
- **Node**: A compute node provisioned by Warewulf
- **Profile**: Default settings applied to multiple nodes
- **wwctl**: The Warewulf control command-line tool

### Why Warewulf?

While Ansible and Salt manage configuration on **running** systems, Warewulf:
- Provisions **bare-metal** compute nodes from scratch
- Deploys complete operating system images over the network
- Scales to thousands of nodes
- Integrates with HPC schedulers like Slurm

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

### Reference Commands

The following commands are what you would use on a properly configured Warewulf cluster:

```bash
# Install Warewulf
# ansible-playbook -i hosts.ini warewulf.yml

# Basic wwctl commands
# wwctl version
# wwctl --help

# Working with Images
# wwctl image import docker://ghcr.io/warewulf/warewulf-rockylinux:9 rockylinux-9
# wwctl image list
# wwctl image shell rockylinux-9

# Working with Overlays
# wwctl overlay list
# wwctl overlay create site-custom

# Working with Nodes
# wwctl node add lci-compute-XX-1 --ipaddr=10.0.1XX.1 --discoverable=true --image=rockylinux-9
# wwctl node list

# Configure services
# wwctl configure dhcp
# wwctl configure nfs
```

---

## Part 4: Combined Exercises - Using Ansible and Salt Together (10-15 minutes)

Now that you've used both tools, let's see how they can complement each other.

### Side-by-Side Comparison

| Feature | Ansible | Salt |
|---------|---------|------|
| **Architecture** | Agentless (SSH) | Master-Minion |
| **Syntax** | YAML | YAML |
| **Learning Curve** | Low | Medium |
| **Scalability** | Good (10K+ nodes) | Excellent (50K+ nodes) |
| **Push vs Pull** | Push (on-demand) | Both |
| **Best For** | Deployment, ad-hoc tasks | Event-driven, real-time |

### Exercise 1: Ansible Installs, Salt Verifies

Use Ansible to install a package across all nodes:

```bash
ansible all_nodes -i hosts.ini -m dnf -a "name=tree state=present" --become
```

Use Salt to verify the install and gather info:

```bash
salt '*' pkg.version tree
salt '*' cmd.run "tree --version"
```

This shows a common pattern: Ansible handles deployment, Salt provides visibility.

### Exercise 2: Ansible Deploys Config, Salt Enforces State

Create a playbook that sets up an MOTD on all nodes:

```bash
cat > deploy_motd.yml << 'EOF'
---
- name: Deploy MOTD to all nodes
  hosts: all_nodes
  become: yes
  tasks:
    - name: Set MOTD
      copy:
        content: |
          ==========================================
          Welcome to {{ inventory_hostname }}
          LCI 2026 Workshop Cluster
          Managed by Ansible and Salt
          ==========================================
        dest: /etc/motd

    - name: Set login banner
      copy:
        content: "Authorized users only.\n"
        dest: /etc/issue
EOF

ansible-playbook -i hosts.ini deploy_motd.yml
```

Verify with Salt:

```bash
salt '*' cmd.run "cat /etc/motd"
```

Now use Salt to create a state that enforces the MOTD content going forward:

```bash
cat > /srv/salt/motd.sls << 'EOF'
motd_file:
  file.managed:
    - name: /etc/motd
    - contents: |
        ==========================================
        This system is managed by Salt
        LCI 2026 Workshop Cluster
        ==========================================
EOF

salt '*' state.apply motd
```

Check the MOTD again:

```bash
salt '*' cmd.run "cat /etc/motd"
```

**Notice:** Salt overwrote the Ansible-deployed MOTD. This demonstrates why choosing **one tool as the source of truth** for each resource matters. If both tools manage the same file, they will conflict.

### Exercise 3: Ansible Orchestrates, Salt Manages State

Use Ansible to trigger Salt state runs across targeted nodes. Create a playbook:

```bash
cat > salt_orchestrate.yml << 'EOF'
---
- name: Use Ansible to orchestrate Salt
  hosts: head
  become: yes
  tasks:
    - name: Sync Salt modules
      command: salt '*' saltutil.sync_all

    - name: Apply user state on all minions
      command: salt '*' state.apply create_user

    - name: Check node health via Salt grains
      command: salt '*' grains.get os
      register: os_info

    - name: Display OS info
      debug:
        var: os_info.stdout_lines

    - name: Install packages via Salt on compute nodes only
      command: salt -G 'id:lci-compute-*' pkg.install vim-enhanced
EOF

ansible-playbook -i hosts.ini salt_orchestrate.yml
```

This pattern is powerful: Ansible provides the workflow orchestration (ordering, error handling, logging), while Salt handles the actual state management on nodes.

---

## Cleanup

> **Important:** Run the Salt cleanup commands **BEFORE** running `destroy.yml`, since `destroy.yml` stops Salt services and the `salt` command will not work after.

### Remove Salt-managed users and files

```bash
salt '*' user.absent workshop_salt remove=True
salt '*' file.remove /etc/motd
```

### Remove Ansible-managed users and files

```bash
ansible all_nodes -i hosts.ini -m user -a "name=workshop state=absent remove=yes" --become
ansible all_nodes -i hosts.ini -m file -a "path=/tmp/lci_test.txt state=absent" --become
ansible all_nodes -i hosts.ini -m file -a "path=/etc/issue state=absent" --become
```

### Remove packages installed during exercises

```bash
ansible all_nodes -i hosts.ini -m dnf -a "name=tree state=absent" --become
salt '*' pkg.remove vim-enhanced
```

### Run destroy playbook

```bash
ansible-playbook -i hosts.ini destroy.yml
```

This removes Salt, test packages, and cleans up the environment.

---

## Summary

You've now used two important HPC infrastructure tools:

1. **Ansible**: Agentless, simple YAML, great for configuration management and deployment
2. **Salt**: Master-minion, event-driven, excellent for real-time orchestration and state enforcement

### Key Takeaways

- **Ansible** is the easiest to learn and requires no agents - perfect for deployment and ad-hoc tasks
- **Salt** offers the best performance and real-time capabilities - great for ongoing state management
- Both tools can work together: Ansible for orchestration and deployment, Salt for state enforcement
- Avoid managing the same resource with both tools to prevent conflicts
- In production HPC environments, **Warewulf** handles bare-metal provisioning, while Ansible/Salt handle post-boot configuration

### When to Use Each Tool

**Ansible:**
- Bootstrapping and initial deployment
- Ad-hoc tasks and one-off commands
- Environments without persistent agents
- Orchestrating workflows across multiple tools

**Salt:**
- Continuous state enforcement
- Event-driven automation and real-time responses
- Large-scale environments (50K+ nodes)
- Complex targeting (by OS, role, custom grains)

### Further Learning

- **Ansible**: Read about Ansible Galaxy (sharing roles), Ansible Tower/AWX (enterprise features)
- **Salt**: Explore Salt Cloud (provisioning), Salt Beacons (monitoring), Salt Reactor (event-driven)
- **Warewulf**: Learn about image templates, custom overlays, and integration with Slurm at [warewulf.org](https://warewulf.org)

---

## Troubleshooting

### Ansible Issues

**Problem**: "Permission denied" when running playbooks
**Solution**: Use `--ask-become-pass` or ensure passwordless sudo is configured

**Problem**: SSH connection failures
**Solution**: Verify SSH keys are distributed: `ansible all_nodes -i hosts.ini -m ping`

**Problem**: Head node fails with SSH error
**Solution**: Ensure `ansible_connection=local` is set for the head node in `hosts.ini`

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

**Problem**: Minion key not accepted
**Solution**: Check key status and accept manually if needed:
```bash
salt-key -L
salt-key -A
```

---

*End of Lab*
