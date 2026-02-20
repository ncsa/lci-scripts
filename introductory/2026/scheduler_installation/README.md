# Steps, scripts, and playbooks related to the Scheduler installation lab 

### Lab objective: 

- SLURM scheduler installation and configuration on the head and compute nodes by using Ansible playbook.

### Playbook steps:

- Create SLURM user & group.
- Create directories for SLURM services and log files.
- Build & Install SLURM packages on the head node.
- Setup munge on the head node.
- Create mysql database for SLURM accounting on the head node.
- Start slurmdbd and slurmctld on the head node.
- Copy munge key to the compute nodes.
- Install the SLURM packages on the compute nodes.
- Start slurmd on the compute nodes.


