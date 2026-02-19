# AGENTS.md

Guidelines for AI coding agents working on the LCI Introductory Workshop repository.

## Project Overview

This repository contains educational materials, scripts, and Ansible playbooks for the Leadership Computing Infrastructure (LCI) Introductory Workshop. It covers HPC cluster setup including head nodes, compute nodes, storage, scheduler installation (Slurm), and parallel programming labs (OpenMP/MPI).

**Primary Languages:** C (parallel computing), Bash (scripts), YAML (Ansible playbooks)

## Build/Test Commands

This repository contains educational materials and infrastructure code. There are no automated build or test commands. Testing is done by:

- **Manual Testing**: Deploy to test cluster environment
- **Syntax Check Ansible**: `ansible-playbook --syntax-check -i inventory playbook.yml`
- **Check Mode**: `ansible-playbook --check -i inventory playbook.yml`
- **Validate C Code**: `gcc -Wall -c file.c` (syntax/compilation check)
- **ShellCheck**: `shellcheck *.sh` (for bash scripts)

## Code Style Guidelines

### C Code (OpenMP/MPI Examples)

- **Indentation**: 2 spaces
- **Braces**: Opening brace on same line for functions, new line for control structures
- **Comments**: Use `/* */` for block comments, `//` acceptable for single line
- **MPI Code**: Include `mpi.h` before standard headers
- **OpenMP**: Use `#pragma omp` with proper indentation
- **Function Comments**: Use block comment headers with Purpose/Modified sections
- **Variable Naming**: snake_case for variables, UPPER_CASE for macros
- **Error Handling**: Always check MPI return codes, handle allocation failures

### Bash Scripts

- **Shebang**: Always use `#!/bin/bash`
- **Indentation**: 2 spaces
- **Variables**: UPPER_CASE for environment/constants, snake_case for local
- **Quotes**: Always quote variables: `"${VAR}"`
- **Error Handling**: `set -euo pipefail` for strict mode
- **Comments**: Explain complex operations
- **SBATCH Directives**: Use descriptive job names, specify all resources

### Ansible Playbooks

- **Indentation**: 2 spaces
- **Naming**: Use descriptive play and task names
- **Structure**: Separate plays with blank lines, use roles for organization
- **Variables**: Define in `group_vars/` or `vars_files:`, use snake_case
- **Tags**: Tag all plays and included tasks for selective execution
- **Handlers**: Use for service restarts after configuration changes
- **Comments**: Use `#` for inline comments, explain complex logic

### YAML Files

- **Indentation**: 2 spaces
- **Quotes**: Quote strings containing special characters
- **Lists**: Use `- ` format with consistent spacing
- **Keys**: snake_case for all keys
- **Boolean Values**: Use `yes`/`no` (Ansible style)

## Project Structure

```
/                          # Root
├── compute_nodes/         # Compute node setup playbooks
├── head_node/            # Head node configuration
├── lecture_openmp_mpi_acc/ # Lecture materials (OpenMP/MPI/ACC)
├── lmod/                 # Lmod module system setup
├── openmp_mpi/           # OpenMP/MPI lab materials
├── run_apps_scheduler/   # Scheduler job submission examples
├── scheduler_installation/ # Slurm scheduler setup
└── storage/              # Storage configuration
```

## Naming Conventions

- **Files**: snake_case (e.g., `mpi_batch.sh`, `playbook_scheduler.yml`)
- **Directories**: snake_case or descriptive names
- **Roles**: kebab-case (e.g., `slurm-rpm-build`, `head-node_nfs_server`)
- **Variables**: snake_case (e.g., `cluster_params`, `num_tasks`)
- **Tags**: snake_case with underscores (e.g., `head_node_play`, `slurm_user`)

## Error Handling Patterns

### C Code
```c
if (NULL == ptr) {
    fprintf(stderr, "Error: allocation failed\n");
    return EXIT_FAILURE;
}
```

### Bash
```bash
set -euo pipefail
if [ -z "${VAR}" ]; then
    echo "Error: VAR not set" >&2
    exit 1
fi
```

### Ansible
```yaml
- name: Ensure directory exists
  file:
    path: "{{ slurm_dir }}"
    state: directory
  register: dir_result
  failed_when: not dir_result.stat.exists
```

## Documentation Standards

- **README.md**: Each major directory should have one
- **Code Comments**: Explain WHY, not WHAT
- **Function Headers**: Include Purpose, Modified date, Parameters
- **Playbook Headers**: Document purpose and target hosts

## Common Patterns

### MPI Program Structure
1. MPI_Init
2. Get rank/size
3. Domain decomposition
4. Communication setup
5. Computation loop
6. MPI_Finalize

### Slurm Batch Script Structure
1. SBATCH directives
2. Environment setup
3. Module loads
4. Execute program
5. Copy results (if using scratch)

## Security Considerations

- Never commit actual credentials or private keys
- Use Ansible vault for sensitive variables
- Validate all user inputs in scripts
- Use least-privilege principles in playbooks

## Dependencies

- **Ansible**: Required for playbook execution
- **GCC**: Required for C code compilation
- **OpenMPI**: Required for MPI programs
- **Slurm**: Required for scheduler operations
