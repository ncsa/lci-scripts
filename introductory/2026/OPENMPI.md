# OpenMPI + Slurm Integration Notes (LCI 2026)

## Overview

This document covers how OpenMPI 5.0.1 integrates with the Slurm scheduler
built from source (v2 playbook), and identifies issues in the existing lab
materials that need to be addressed before the workshop.

---

## How OpenMPI and Slurm Work Together

### PMIx is the glue

Slurm was built with `--with-pmix` and `slurm.conf` has `MpiDefault=pmix`.
OpenMPI 5.x uses PMIx natively (it bundles its own PMIx library). When a user
launches an MPI job with `srun`, Slurm's PMIx plugin handles process spawning
and OpenMPI connects to it automatically. No extra configuration is needed.

### srun vs mpirun

| Launcher | How it works | Recommended? |
|----------|-------------|--------------|
| `srun --mpi=pmix` | Slurm launches MPI processes directly via PMIx | Yes |
| `srun` (no flag) | Works because `MpiDefault=pmix` is in slurm.conf | Yes |
| `mpirun` inside sbatch | OpenMPI's PRRTE launches processes; may or may not integrate with Slurm properly | Not recommended |

**Best practice:** Always use `srun` to launch MPI jobs under Slurm. This
ensures Slurm has full control over process placement, accounting, and signal
delivery. Using `mpirun` inside a Slurm batch script can work but bypasses
Slurm's process management and may cause accounting inaccuracies.

### PRRTE (PMIx Reference RunTime Environment)

The MPI lab installs PRRTE v3.0.3 separately. PRRTE is what OpenMPI uses
internally for `mpirun` when launching outside of Slurm. Under Slurm, PRRTE
is not needed because `srun` handles process launch via PMIx directly. Having
PRRTE installed won't break anything, but students should understand that
`srun` is the correct launcher for Slurm-managed jobs.

---

## Issues in Lab_Run_Application_via_Scheduler.md

The lab at `run_apps_scheduler/Lab_Run_Application_via_Scheduler.md` has
several issues that will cause failures or confusion with the current
Slurm + OpenMPI setup.

### Issue 1: mpi_batch.sh uses `mpirun` instead of `srun`

**File:** `openmp_mpi/Lab_MPI/MPI/mpi_batch.sh`

```bash
# Current (problematic):
mpirun  mpi_heat2D.x

# Should be:
srun --mpi=pmix mpi_heat2D.x
```

**Why it fails:** With OpenMPI 5.x under Slurm, `mpirun` may not properly
integrate with Slurm's process management. It can fail to launch across
nodes, produce incorrect accounting, or hang. The lab document (Section 5)
even tells students to copy this script and replace `mpirun` with `srun`,
but the original script will fail first.

### Issue 2: mpi_batch.sh requests 4 nodes (only 2 exist)

**File:** `openmp_mpi/Lab_MPI/MPI/mpi_batch.sh` and lab Section 5

The lab markdown shows `--nodes=4` in the example, but the actual batch
script has `--nodes=2`. The cluster only has 2 compute nodes
(`lci-compute-XX-1` and `lci-compute-XX-2`), so requesting 4 nodes would
cause the job to pend forever. The markdown example needs to match the
actual script (--nodes=2).

### Issue 3: poisson_batch.sh uses `mpirun`

**File:** `openmp_mpi/Lab_MPI/MPI/poisson_batch.sh`

```bash
# Current:
mpirun poisson_mpi.x 1024 0.00001

# Should be:
srun --mpi=pmix poisson_mpi.x 1024 0.00001
```

Same issue as mpi_batch.sh. Section 8 of the lab has students compile
`poisson_mpi.c` with `mpicc` and submit via this script.

### Issue 4: Section 8 uses `mpicc` directly

The lab instructs:
```bash
mpicc -o poisson_mpi.x poisson_mpi.c
```

This will only work if OpenMPI's bin directory is in PATH. Students need
to either:
- Have `/opt/openmpi/5.0.1/bin` in their PATH (via module or profile.d), or
- Source the OpenMPI environment before compiling

### Issue 5: openmp_batch.sh references partition `lcilab`

**File:** `openmp_mpi/Lab_MPI/OpenMP/openmp_batch.sh`

The actual script correctly uses `--partition=lcilab`, which matches the
Slurm config. However, the lab markdown (Section 5) shows
`--partition=lci` in the example code block. Students reading the markdown
will see the wrong partition name.

### Issue 6: Lab references `heated_plate_openmp.x` but script uses `heated_plate.x`

Section 3 tells students to run `heated_plate_openmp.x` but the batch
script and later sections reference `heated_plate.x`. The source file is
`heated_plate_openmp.c`. Students need to know the correct compiled binary
name.

### Issue 7: Pre-compiled binaries may not exist

The lab assumes binaries like `heated_plate.x` and `mpi_heat2D.x` already
exist. These need to be compiled during the OpenMP/MPI lab first. The note
at the top of the lab mentions copying the code, but doesn't mention that
compilation must have been completed.

---

## Batch Script Fixes Needed

### mpi_batch.sh (current)
```bash
#!/bin/bash
#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

mpirun  mpi_heat2D.x
```

### mpi_batch.sh (fixed)
```bash
#!/bin/bash
#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

srun --mpi=pmix mpi_heat2D.x
```

### poisson_batch.sh (current)
```bash
#!/bin/bash
#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

mpirun poisson_mpi.x 1024 0.00001
```

### poisson_batch.sh (fixed)
```bash
#!/bin/bash
#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

srun --mpi=pmix poisson_mpi.x 1024 0.00001
```

---

## OpenMPI Environment Setup

For OpenMPI commands (`mpicc`, `mpirun`, `mpiexec`) to work, the OpenMPI
installation must be in the user's PATH and LD_LIBRARY_PATH. The MPI lab
installs OpenMPI to `/opt/openmpi` via RPM with `install_in_opt 1`.

Students need this in their environment (or via a module):

```bash
export PATH=/opt/openmpi/5.0.1/bin:$PATH
export LD_LIBRARY_PATH=/opt/openmpi/5.0.1/lib:$LD_LIBRARY_PATH
```

---

## Slurm Configuration Relevant to MPI

From `slurm.conf.j2`:

| Setting | Value | Purpose |
|---------|-------|---------|
| `MpiDefault` | `pmix` | Default MPI launch plugin; means `--mpi=pmix` is implicit |
| `ProctrackType` | `proctrack/cgroup` | Process tracking via cgroups |
| `TaskPlugin` | `task/cgroup,task/affinity` | CPU affinity and cgroup task management |
| `SelectType` | `select/cons_tres` | Consumable trackable resources |
| `LaunchParameters` | `enable_nss_slurm,use_interactive_step` | NSS plugin and interactive step support |

Because `MpiDefault=pmix` is set, students can use just `srun` without
`--mpi=pmix` and it will work. The `--mpi=pmix` flag is only needed if
MpiDefault were set to something else.

---

## Runtime Library Dependencies

The Slurm playbook (v2) now installs these runtime packages on compute
nodes to support the Slurm binaries:

- hwloc, pmix, json-c, libjwt, ucx, lua, http-parser, lz4, numactl, dbus

OpenMPI's RPM install should handle its own dependencies, but if students
see `libXXX.so: cannot open shared object file` errors, the fix is to
install the missing package on the compute nodes via:

```bash
clush -g compute "dnf install -y <package-name>"
```

---

## Summary Checklist Before the Lab

- [ ] Slurm is running (`sinfo` shows nodes)
- [ ] OpenMPI is installed on head and compute nodes
- [ ] OpenMPI bin/lib are in PATH/LD_LIBRARY_PATH for mpiuser
- [ ] MPI binaries are compiled (`mpi_heat2D.x`, `poisson_mpi.x`, `heated_plate.x`)
- [ ] Batch scripts use `srun --mpi=pmix` instead of `mpirun`
- [ ] Lab markdown partition references match `lcilab`
- [ ] Slurm accounts created (`lci2026` account, `mpiuser` and `rocky` users)
- [ ] `srun --mpi=list` shows pmix support
