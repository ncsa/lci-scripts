# Lab steps, scripts, and playbooks related to the Head node lab .

- SSH to the head node.

## Host based SSH authentication setup on the cluster

- Download the lci-scripts folder from git
```bash
git clone git@github.com:ncsa/lci-scripts.git
```

- Copy folder SSH_hostbased into your home directory:
```bash
cp -a lci-scripts/introductory/SSH_hostbased .
```

- Install package ansible:
```bash
sudo dnf install ansible
```
- Step into directory SSH_hostbased:
```bash
cd SSH_hostbased
```

- Check out the content of files `ansible.cfg`, `hosts.ini`, `gen_hosts_equiv.sh`, `ssh_key_scan.sh`, and playbook `host_based_ssh.yml`.

- Generate file `hosts.equiv` and `ssh_known_hosts` by running two shell scripts:
```bash
./gen_hosts_equiv.sh
./ssh_key_scan.sh
```

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
