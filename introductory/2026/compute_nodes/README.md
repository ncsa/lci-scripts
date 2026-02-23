# Steps, scripts, and playbooks related to the compute node lab. 

## Lab objective 

By performing the tasks below on the compute nodes, we

 - Enable the EPEL repo and powertools in dnf

 - Ensure timezone is in sync with America/Chicago

 - Install perl, perl-DBI, autofs packages

 - Set autofs maps to mount /head/NFS directory from the head node.

## Lab steps

- Copy folder Compute_node_playbook into your home directory:
```bash
cd
cp -a lci-scripts/introductory/compute_nodes/Compute_node_playbook .
cd Compute_node_playbook
```

- Checkout the content of playbook_compute_node.yml and directory roles.

- Check the playbook for syntactic errors:
```bash
ansible-playbook playbook_compute_node.yml --syntax-check 
```

- Perform the dry run of the playbook:
```bash
ansible-playbook playbook_compute_node.yml --check
```

- Run the playbook:
```bash
ansible-playbook playbook_compute_node.yml
```

- Check of you can get /head/NFS mounted on the compute nodes. 
```bash
ssh lci-compute-01-1
cd /head/NFS
df -h
```
Directory /head/NFS should be mounted.

- Exit from the compute node.

- All the installations and settings above can be removed via playbook destroy.yml

