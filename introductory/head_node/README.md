# Steps, scripts, and playbooks related to the Head node lab .

## Lab objective:

- Setting up ssh host-based authentication and Ansible cluster management. Learn how to use Ansible to  deploy software packages on the head node.

### Lab Steps:

- ```ssh``` to the head node.

- Download the lci-scripts folder from git
```bash
git clone https://github.com/ncsa/lci-scripts.git 
```

- Install Ansible and configure Ansible environment on the head node.

- Setting ssh host-based authentication.

- Use Ansible playbooks to:

    - Install packages.

    - Set time synchronization.

    - Configure NFS exports.

<hr>

## Host based SSH authentication setup on the cluster

### Motivation
There are three commonly used SSH authentication techniques:

   - user name and password
   - public/private keys
   - host based

Host-based authentication is needed for users to ssh to the compute nodes without password. An alternative solution would be using the private/public ssh keys, but that would need to be done for every user on the cluster.

To enable ssh host based authentication on a client, one needs to modify ssh_config file.

On the server side, modify sshd_config.

Collect the ssh public node host keys in file /etc/ssh/ssh_known_hosts.

Restart sshd daemon.

### Steps
- Copy folder SSH_hostbased into your home directory:
```bash
cp -a lci-scripts/introductory/SSH_hostbased .
```

- Install package ansible:
```bash
sudo dnf install ansible-core
```
- Step into directory SSH_hostbased:
```bash
cd SSH_hostbased
```

- Check out the content of files `ansible.cfg`, `hosts.ini`, `gen_hosts_equiv.sh`, `ssh_key_scan.sh`, and playbook `host_based_ssh.yml.


- Generate file `hosts.equiv` and `ssh_known_hosts` by running two shell scripts:
```bash
./gen_hosts_equiv.sh
./ssh_key_scan.sh
```

Now we can test the ansible shell command by running a basic command on the hosts. Lets run a command on the compute nodes and see how that would look:

```bash
sudo ansible all_nodes -m ansible.builtin.shell -a "uname -n"
```

Did the command execute on all of the compute nodes?

Above we use ansible command ansible on the host group all_nodes.

-m for the ansible.builtin.shell module name

-a for the module arguements

uname -n - command we want to execute on hosts defined as all_nodes

We will use the ansible.bultin.shell module plus many other modules in the coming labs. We also have a task and a plays directory provisioned for you which we use to execute individual plays. In addition we also use a playbook to play all of the tasks at once.

Playbook `host_based_ssh.yml` needs to run as root.

- Check ansible playbook `host_based_ssh.yml` for syntactic errors:
```bash
sudo ansible-playbook host_based_ssh.yml --syntax-check 
```

- Perform the dry run of the playbook:
```bash
sudo ansible-playbook host_based_ssh.yml --check
```

- Run the playbook:
```bash
sudo ansible-playbook host_based_ssh.yml
```

- Check if you can ssh as user rocky to nodes lci-compute-01-1 and lci-compute-01-2 without password.

You should be able to ssh between the nodes and elevate privileges to root via `sudo`.

- To remove the SSH host based authentication settings, there is playbook ```remove_host_based_ssh.yml```

<hr>

## Installation roles an tasks on the head node.

By performing the roles below on the head node, we

- Enable the EPEL repo and powertools in dnf

- Ensure timezone is in sync with America/Chicago

- Install head node packages, including compiler, development tools, rpmbuild tools, mariadb (MySQL server)

### Steps:

As user rocky, copy directory Head_node_playbook into the home directory:

```bash
cd 
cp -a lci-scripts/introductory/head_node/Head_node_playbook .
cd Head_node_playbook
```

Check out files ansible.cfg, hosts.ini, and playbook.yml.

Run ansible-playbook as user rocky in this exercise.

Check for syntactic errors:
```bash
ansible-playbook --syntax-check playbook.yml
```

Do a dry-run:
```bash
ansible-playbook --check playbook.yml
```
Notice an error due to unfound package. This will go away after the power tools are installed on the head node.

Run the playbook:
```bash
ansible-playbook playbook.yml
```

Verify that service mariadb is running:
```bash
systemctl status mariadb
```

Check if the NFS server exports directory /head/NFS to the compute nodes:
```bash
showmount -e
```

It should show the exportd directory and the clients.

The installed packages, files, and directories in this lab can be removed via playbook destroy.yml
