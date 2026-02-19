# Scheduler Installation Playbook - Fixes Needed

## Error Analysis

The playbook failed during the PMIx RPM build process with missing build dependencies:

```
error: Failed build dependencies:
	hwloc-devel is needed by pmix-4.2.8-1.el9.x86_64
	libevent-devel is needed by pmix-4.2.8-1.el9.x86_64
	python3-devel is needed by pmix-4.2.8-1.el9.x86_64
```

## Required Fix

Add the missing development packages to be installed before attempting to build PMIx RPMs.

### Option 1: Add to Existing Role (Recommended)

Modify `@scheduler_installation/Scheduler_installation_playbook/roles/slurm-rpm-build/tasks/pmix-rpm-build.yml` to install the required dependencies before building:

```yaml
- name: Install PMIx build dependencies
  ansible.builtin.dnf:
    name:
      - hwloc-devel
      - libevent-devel
      - python3-devel
    state: present

- name: Checking to see if the pmix SRC RPM exists
  ...
```

### Option 2: Add to Playbook Pre-tasks

Add a pre-task section to `@scheduler_installation/Scheduler_installation_playbook/playbook_scheduler.yml`:

```yaml
---
####### head node play ############
- name: Head node Scheduler configuration
  vars_files: group_vars/cluster_params.yml
  become: yes
  hosts: head
  connection: local
  tags: head_node_play
  
  pre_tasks:
    - name: Install build dependencies for PMIx
      ansible.builtin.dnf:
        name:
          - hwloc-devel
          - libevent-devel
          - python3-devel
        state: present
  
  roles: 
    - slurm-user
    - slurm-rpm-build
    - head-node_munge_key
    - slurmdbd
```

## Missing Package Reference

The following packages need to be installed on the head node before running the playbook:

| Package | Purpose |
|---------|---------|
| `hwloc-devel` | Hardware locality development headers |
| `libevent-devel` | Event-driven programming library headers |
| `python3-devel` | Python 3 development headers |

## Additional Notes

- These are build-time dependencies, not runtime dependencies
- They are required for compiling PMIx from source RPM
- The packages should be installed before the `slurm-rpm-build` role runs
- Consider also installing `rpm-build` and `make` if not already present

## Verification After Fix

After applying the fix, re-run the playbook:

```bash
ansible-playbook playbook_scheduler.yml
```

The PMIx build should complete successfully without the "Failed build dependencies" error.
