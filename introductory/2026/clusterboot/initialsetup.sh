#!/bin/sh
ANSIBLE_HOSTS_FILE='hosts.yml'
myclusternumber=$(hostname | cut -d- -f 3)
thisyear=$(date +%Y)

# Since we've sudo'd to root, change to the root homedir to start
cd ~

# We're going to need the latest version of ansible
sudo dnf install -y python3-pip
pip3 install ansible

# Ansible puts things in /usr/local/bin, which isn't in the PATH,
# so add that to the .bashrc and then source it
echo "PATH=${PATH}:/usr/local/bin" >> ~/.bashrc
source ~/.bashrc

# Get the LCI scrips repo and change to the appropriate directory for starting the process
git clone git@github.com:ncsa/lci-scripts.git
cd lci-scripts/introductory/${thisyear}/clusterboot

# Seed the hosts for ansible
sed -i 's/THISCLUSTER/'${myclusternumber}'/' $ANSIBLE_HOSTS_FILE

# Install the required ansible libraries
ansible-galaxy collection install ansible.posix

# Run ansible to install everything
ansible-playbook -i hosts.yml playbook.yml
