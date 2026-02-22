# Configuration Management Lab - Todo List
# Ansible, Salt, and Warewulf

Replace `XX` with your cluster number (e.g., 02, 03, etc.) in all commands.

## 1. Setup

```bash
sudo -i
cd ~
git clone https://github.com/ncsa/lci-scripts.git
cp -a lci-scripts/introductory/2026/config_mgmt/Config_mgmt_playbook .
cd Config_mgmt_playbook
vim hosts.ini
:%s/XX/<clusternumber>/g
:wq
```

---

## 2. Ansible Recap (10 min)

```bash
# Test connectivity
ansible all_nodes -i hosts.ini -m ping

# Ad-hoc commands
ansible all_nodes -i hosts.ini -a "uptime"
ansible compute -i hosts.ini -m dnf -a "name=htop state=present" --become

# Create user playbook
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
    - name: Ensure .ssh directory exists
      file:
        path: /home/workshop/.ssh
        state: directory
        owner: workshop
        group: workshop
        mode: '0700'
EOF

ansible-playbook -i hosts.ini create_user.yml
ansible all_nodes -i hosts.ini -a "id workshop"
```

---

## 3. Salt Setup and Test (15 min)

```bash
# Install on head node
dnf install -y salt-master salt-minion

cat > /etc/salt/master.d/lci.conf << 'EOF'
auto_accept: True
file_roots:
  base:
    - /srv/salt
pillar_roots:
  base:
    - /srv/pillar
EOF

mkdir -p /srv/salt /srv/pillar
systemctl enable --now salt-master

# Configure minion
cat > /etc/salt/minion.d/master.conf << 'EOF'
master: lci-head-XX-1
id: lci-head-XX-1
EOF
systemctl enable --now salt-minion

# Install on compute nodes
clush -g compute "dnf install -y salt-minion"
clush -g compute "echo 'master: lci-head-XX-1' > /etc/salt/minion.d/master.conf"
clush -g compute "echo 'id: lci-compute-XX-1' > /etc/salt/minion.d/id.conf" --host lci-compute-XX-1
clush -g compute "echo 'id: lci-compute-XX-2' > /etc/salt/minion.d/id.conf" --host lci-compute-XX-2
clush -g compute "systemctl enable --now salt-minion"

# Verify
salt-key -L
salt '*' test.ping

# Create and apply state
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
EOF

salt '*' state.apply create_user
salt '*' grains.get os
```

---

## 4. Warewulf Setup and Test (15 min)

```bash
# Install Warewulf
ansible-playbook -i hosts.ini warewulf.yml

# Import base image
wwctl image import docker://ghcr.io/warewulf/warewulf-rockylinux:9 rockylinux-9
wwctl image list --long

# Modify image
wwctl image shell rockylinux-9
dnf -y install htop vim
exit

# Create custom overlay
wwctl overlay create site-custom
cat > /var/lib/warewulf/overlays/site-custom/rootfs/etc/motd << 'EOF'
Welcome to {{.Id}}
This node is part of the LCI 2026 workshop cluster.
EOF
wwctl overlay build

# Add nodes
wwctl node add lci-compute-XX-1 --ipaddr=10.0.2.1 --discoverable=true --image=rockylinux-9
wwctl node add lci-compute-XX-2 --ipaddr=10.0.2.2 --discoverable=true --image=rockylinux-9
wwctl node list --all

# Configure services
wwctl configure dhcp
wwctl configure nfs
```

---

## 5. Comparison Exercise (10-15 min)

### Combined Ansible + Warewulf:
```bash
cat > setup_nodes.yml << 'EOF'
---
- name: Configure Warewulf nodes
  hosts: head
  become: yes
  tasks:
    - name: Add compute nodes
      command: |
        wwctl node add {{ item.name }} \
          --ipaddr={{ item.ip }} \
          --image=rockylinux-9 \
          --discoverable=true
      loop:
        - { name: 'lci-compute-XX-1', ip: '10.0.2.1' }
        - { name: 'lci-compute-XX-2', ip: '10.0.2.2' }
    - name: Configure DHCP
      command: wwctl configure dhcp
    - name: Build overlays
      command: wwctl overlay build
EOF

ansible-playbook -i hosts.ini setup_nodes.yml
```

### Combined Salt for post-provisioning:
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
EOF

salt 'lci-compute-*' state.apply slurm_client
```

---

## 6. Cleanup (Optional)

```bash
# Run destroy playbook
ansible-playbook -i hosts.ini destroy.yml
```

---

## Done!

You've now used three major infrastructure tools:
- **Ansible**: Agentless, YAML-based configuration
- **Salt**: Event-driven master-minion automation  
- **Warewulf**: HPC cluster bare-metal provisioning
