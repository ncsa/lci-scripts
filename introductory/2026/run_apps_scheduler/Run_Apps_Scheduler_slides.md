---
marp: true
theme: default
paginate: true
header: "LCI 2026 Workshop"
footer: "Running Applications via the Slurm Scheduler"
style: |
  section {
    font-size: 24px;
  }
  h1 {
    color: #2e5090;
  }
  h2 {
    color: #2e5090;
  }
  code {
    font-size: 20px;
  }
  pre {
    font-size: 18px;
  }
  table {
    font-size: 20px;
  }
---

# Running Applications via the Slurm Scheduler

## LCI Introductory Workshop 2026

**Objective:** Learn Slurm commands to submit, monitor, terminate jobs, and review accounting information.

---

## Agenda

1. Slurm Account & User Setup
2. Cluster Resource Monitoring (`sinfo`, `squeue`)
3. Interactive Allocation with `salloc`
4. Interactive Runs with `srun`
5. MPI Runs & PMIx Integration
6. Batch Submission with `sbatch`
7. Anatomy of a Batch Script
8. Job Management (`scancel`, concurrent jobs)
9. Monitoring & Accounting (`sstat`, `sacct`)
10. Cluster Inspection with `scontrol`

---

## 1. Slurm Account & User Setup

Before running jobs, users and accounts must exist in Slurm for proper accounting and resource tracking.

**Accounts** in Slurm are similar to POSIX groups in Linux.

```bash
# Create an account (group)
sudo sacctmgr -i add account lci2026 Description="LCI 2026 workshop"

# Create users and assign to the account
sudo sacctmgr -i create user name=mpiuser cluster=cluster account=lci2026
sudo sacctmgr -i create user name=rocky  cluster=cluster account=lci2026

# Verify associations
sacctmgr list associations format=user,account
```

---

## 2. Cluster Resource Monitoring

### `sinfo` -- What resources are available?

```bash
sinfo            # Overview: partitions, node states
sinfo -N -l      # Per-node detail: CPUs, memory, state
```

### `squeue` -- What is running or pending?

```bash
squeue           # All jobs in the queue
```

| State | Meaning |
|-------|---------|
| `R`   | Running |
| `PD`  | Pending (waiting for resources) |
| `CG`  | Completing |

---

## 3. Interactive Allocation: `salloc`

`salloc` allocates resources but keeps your shell on the **head node**.

```bash
salloc -n 2                   # Request 2 CPU cores
```

Then run your application:

```bash
export OMP_NUM_THREADS=2
./heated_plate.x              # OpenMP app runs on allocated resources
```

When done:

```bash
exit                          # Release the allocation
sinfo                         # Nodes return to idle
sacct -u mpiuser              # Confirm completed job
```

---

## 4. Interactive Runs: `srun`

`srun` allocates resources **and** runs directly on a compute node.

```bash
srun -n 2 --pty bash          # Get a shell ON a compute node
```

You are now on the compute node -- run interactively:

```bash
export OMP_NUM_THREADS=2
./heated_plate.x
exit                          # Release resources
```

### Key difference: `salloc` vs `srun`

| | `salloc` | `srun --pty bash` |
|---|----------|-------------------|
| Shell location | Head node | Compute node |
| Use case | Run multiple commands with allocated resources | Quick interactive session |

---

## 5. MPI Runs with `srun` & PMIx

**PMIx** is the glue between Slurm and MPI -- it handles process spawning.

```bash
# Check available MPI plugins
srun --mpi=list               # Should show: pmix, pmix_v4

# Launch MPI jobs
srun --mpi=pmix -n 4 mpi_heat2D.x
```

### `srun` vs `mpirun` under Slurm

| Launcher | Recommended? | Why |
|----------|:---:|------|
| `srun --mpi=pmix` | Yes | Slurm controls process placement & accounting |
| `srun` (no flag) | Yes | `MpiDefault=pmix` in slurm.conf makes it implicit |
| `mpirun` in sbatch | No | Bypasses Slurm process management |

**Best practice:** Always use `srun` to launch MPI jobs under Slurm.

---

## 6. Batch Submission: `sbatch`

`sbatch` submits a script to run **unattended** on the cluster.

```bash
sbatch mpi_batch.sh           # Submit and get a job ID
squeue                        # Watch it run
cat slurm-<jobid>.out         # Check output after completion
```

This is the primary way production jobs are run:
- No interactive session needed
- Jobs queue and run when resources are available
- Output captured to files

---

## 7. Anatomy of a Batch Script

### MPI Example

```bash
#!/bin/bash
#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

srun --mpi=pmix mpi_heat2D.x
```

### OpenMP Example (with scratch directory)

```bash
#!/bin/bash
#SBATCH --job-name=OMP_run
#SBATCH --output=slurm.out
#SBATCH --error=slurm.err
#SBATCH --partition=lcilab
#SBATCH --ntasks-per-node=2

export OMP_NUM_THREADS=$SLURM_JOB_CPUS_PER_NODE
MYTMP="/tmp/$USER/$SLURM_JOB_ID"
mkdir -p $MYTMP
cp $SLURM_SUBMIT_DIR/heated_plate.x $MYTMP
cd $MYTMP
./heated_plate.x > run.out-$SLURM_JOB_ID
cp $MYTMP/run.out-$SLURM_JOB_ID $SLURM_SUBMIT_DIR
rm -rf $MYTMP
```

Local scratch I/O is faster than NFS shared filesystems.

---

## 8. Job Management

### Cancel a job: `scancel`

```bash
sbatch -w lci-compute-XX-1 openmp_batch.sh
squeue                        # Note the job ID
scancel -j <jobid>            # Terminate it
```

### Concurrent jobs & resource contention

```bash
srun -n 2 --pty bash          # Holds 2 CPUs
sbatch mpi_batch.sh           # This job will PEND
squeue
```

```
  JOBID PARTITION     NAME     USER ST  TIME NODES NODELIST(REASON)
     31    lcilab MPI_test  mpiuser PD  0:00     2 (Resources)
     30    lcilab     bash  mpiuser  R  1:38     1 compute1
```

Exit `srun` to free resources -- the pending job starts automatically.

---

## 9a. Monitoring Running Jobs: `sstat`

`sstat` shows real-time resource usage for **running** jobs.

```bash
sstat -j <jobid>

# Formatted output
sstat -p --format=AveCPU,AvePages,AveRSS,AveVMSize,JobID -j <jobid>
```

Example output:

```
AveCPU|AvePages|AveRSS|AveVMSize|JobID|
00:02:30|7|57000K|65404K|29.0|
```

Useful for checking memory usage and CPU utilization mid-run.

---

## 9b. Job Accounting: `sacct`

`sacct` reports on **completed** (and running) jobs.

```bash
sacct --helpformat                  # See all available fields
sacct -u mpiuser                    # All jobs for a user
sacct -j <jobid> --format="JobID,JobName,State,Start,End"
```

### Formatted output example

```bash
sacct -j 61 --format="JobID,JobName%15,State,NodeList%20,CPUTime"
```

```
JobID                JobName      State             NodeList    CPUTime
------------ --------------- ---------- -------------------- ----------
61             MPI_test_case  COMPLETED lci-compute-01-[1-2]   00:32:32
61.batch               batch  COMPLETED     lci-compute-01-1   00:16:16
61.0                   prted  COMPLETED     lci-compute-01-2   00:32:36
```

Use `%N` width specifiers (e.g., `JobName%15`) to prevent truncation.

---

## 10. Cluster Inspection: `scontrol`

`scontrol` reads (and modifies) Slurm configuration at runtime.

```bash
# Slurm configuration overview
scontrol show config

# Detailed node information
scontrol show node lci-compute-XX-1

# Detailed job information
scontrol show job <jobid>
```

Shows everything: allocated CPUs, memory limits, time limits, node features, job scripts, environment variables, and more.

---

## Slurm Commands Cheat Sheet

| Command | Purpose |
|---------|---------|
| `sacctmgr` | Manage accounts and users |
| `sinfo` | View cluster/node status |
| `squeue` | View job queue |
| `salloc` | Allocate resources (shell stays on head node) |
| `srun` | Run interactively on compute nodes |
| `sbatch` | Submit batch job scripts |
| `scancel` | Cancel/terminate a job |
| `sstat` | Monitor running job resources |
| `sacct` | View completed job accounting |
| `scontrol` | Inspect/modify Slurm config, nodes, jobs |

---

## Key Takeaways

- **Use `srun`** (not `mpirun`) to launch MPI jobs under Slurm
  - PMIx handles the Slurm-MPI integration automatically
- **`salloc`** for multi-step interactive work; **`srun --pty bash`** for quick sessions
- **`sbatch`** is the standard for production -- jobs queue and run unattended
- **Scratch directories** on local disks improve I/O performance
- **`sacct`** with format strings is your go-to for post-job analysis
- **`scontrol show`** gives you deep visibility into the cluster state

---

## Lab Time

**You will practice:**

1. Creating Slurm accounts and users
2. Allocating resources with `salloc` and `srun`
3. Submitting OpenMP and MPI batch jobs with `sbatch`
4. Monitoring jobs with `squeue`, `sstat`, and `sacct`
5. Canceling jobs and observing resource contention
6. Inspecting the cluster with `scontrol`

**Lab guide:** `Lab_Run_Application_via_Scheduler.md`

---

<!-- _class: lead -->

# Questions?

