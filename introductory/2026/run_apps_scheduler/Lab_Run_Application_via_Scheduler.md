
## Lab: Build a Cluster: Run Application via Scheduler

**Objective:** learn SLURM commands to submit, monitor, terminate computational jobs, and check completed job accounting info.

**Note:** All source code and compiled binaries should be run from `/scratch/` (e.g., `/scratch/mpiuser/`), which is the only shared filesystem visible from all compute nodes. The home directory is not mounted on compute nodes.

**Steps:**

- Create accounts and users in SLURM

- Create Slurm partition for jobs

- Browse the cluster resources with `sinfo`

- Simple `sbatch` examples (hello, hostname, environment, arrays)

- Resource allocation via `salloc` for application runs

- Using `srun` for interactive runs

- `sbatch` to submit MPI/OpenMP job scripts 

- Terminate a job with `scancel`

- Concurrently submitted jobs and resources

- Job monitoring with `squeue` and `sstat` commands.

- Job statistics with `sacct` commands

- Command `scontrol show` exercises

### 1. Create cluster account and users in SLURM

For correct accounting, association, and resource assignments, users and accounts should be created in SLURM.

Accounts in SLURM have the meaning like posix groups in Linux.

We create account (group) lci2026:

```bash
sudo sacctmgr -i add account lci2026 Description="LCI 2026 workshop"
```

We create users `mpiuser` and `rocky` and assign them to cluster "cluster" and account (group) lci2026:

```bash
sudo sacctmgr -i create user name=mpiuser cluster=cluster account=lci2026
sudo sacctmgr -i create user name=rocky cluster=cluster account=lci2026
```

Check the accounts and users:

```bash
sacctmgr list associations format=user,account
```

### 1a. Create Slurm partition

A partition in Slurm is a logical group of nodes where jobs can be submitted. Create the lcilab partition that will be used for all job submissions:

```bash
sudo scontrol create PartitionName=lcilab Nodes=ALL Default=YES MaxTime=04:00:00 State=UP
```

Verify the partition was created:

```bash
sinfo
```

**To modify an existing partition** (e.g., change MaxTime):

```bash
sudo scontrol update PartitionName=lcilab MaxTime=08:00:00
```

### 2. Cluster resources monitoring

To see what nodes are allocated, used, and idle (available), run command `sinfo`:

```bash
sinfo
```

To see the details about available and allocated resources on the nodes:

```bash
sinfo -N -l
```

To see running and pending jobs in the queue:

```bash
squeue
```

### 3. Simple sbatch examples

This section demonstrates basic `sbatch` usage with simple scripts. No MPI or OpenMP is needed for these examples.

The source files are organized in numbered subdirectories under `simple/`:

```bash
sudo su - mpiuser
cd /scratch/mpiuser/simple
```

#### 3a. Hello World - simplest sbatch job

**01-hello/hello.sh** - A simple greeting script:

```bash
#!/bin/bash
# hello.sh - Simple greeting script
echo "Hello from $HOSTNAME"
echo "Job ID: $SLURM_JOB_ID"
echo "Running at: $(date)"
```

**01-hello/hello_batch.sh** - The Slurm batch script:

```bash
#!/bin/bash

#SBATCH --job-name=hello_job
#SBATCH --output=hello.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:01:00

./hello.sh
```

To run:

```bash
# Before: Check cluster state
sinfo
squeue

cd 01-hello
sbatch hello_batch.sh

# After: Check job status
squeue
scontrol show job <jobid>

# Wait for completion, then check output
sleep 5
cat hello.out
cd ..
```

#### 3b. Hostname across multiple tasks

**02-hostname/hostname_array.sh** - Shows which node each task runs on:

```bash
#!/bin/bash
# hostname_array.sh - Demonstrates task distribution
echo "Task $SLURM_PROCID on host $HOSTNAME"
```

**02-hostname/hostname_batch.sh** - Multi-task batch script:

```bash
#!/bin/bash

#SBATCH --job-name=hostname_job
#SBATCH --output=hostname.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=4
#SBATCH --time=00:01:00

srun hostname_array.sh
```

To run:

```bash
# Before: Check node availability
sinfo -N

cd 02-hostname
sbatch hostname_batch.sh

# After: See which nodes were allocated
squeue
scontrol show job <jobid>

# Wait for completion
cat hostname.out
cd ..
```

#### 3c. Count script

**03-count/count.sh** - A simple script that counts from 1 to a given number:

```bash
#!/bin/bash
# count.sh - A simple script that counts from 1 to a given number
# Usage: ./count.sh [number]
# Default: counts to 10 if no argument provided

MAX=${1:-10}

echo "Counting from 1 to $MAX on host $(hostname)"
echo "Started at: $(date)"
echo "---"

for i in $(seq 1 $MAX); do
    echo "$i"
    sleep 1
done

echo "---"
echo "Finished at: $(date)"
```

**03-count/count_batch.sh** - The Slurm batch script:

```bash
#!/bin/bash

#SBATCH --job-name=count_job
#SBATCH --output=slurm_count.out
#SBATCH --error=slurm_count.err
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:05:00

bash count.sh 20
```

To run:

```bash
# Before
squeue

cd 03-count
sbatch count_batch.sh

# After: Watch job progress (runs for 20 seconds)
squeue
watch -n 1 squeue   # Press Ctrl+C to stop watching

# Check output after completion
cat slurm_count.out
cd ..
```

#### 3d. Slurm environment variables

**04-env/env_check.sh** - Display Slurm environment variables:

```bash
#!/bin/bash
# env_check.sh - Display Slurm environment variables
echo "=== Slurm Environment ==="
echo "Job ID:          $SLURM_JOB_ID"
echo "Job Name:        $SLURM_JOB_NAME"
echo "Number of Tasks: $SLURM_NTASKS"
echo "Number of Nodes: $SLURM_JOB_NUM_NODES"
echo "Node List:       $SLURM_JOB_NODELIST"
echo "CPUs per Node:   $SLURM_JOB_CPUS_PER_NODE"
echo "Partition:       $SLURM_JOB_PARTITION"
echo "Working Dir:     $SLURM_SUBMIT_DIR"
echo "========================="
```

**04-env/env_batch.sh** - Batch script for environment check:

```bash
#!/bin/bash

#SBATCH --job-name=env_check
#SBATCH --output=env.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:01:00

./env_check.sh
```

To run:

```bash
# Before
sinfo

cd 04-env
sbatch env_batch.sh

# After
squeue
sleep 3
cat env.out
cd ..
```

#### 3e. Job Arrays

**05-array/array_task.sh** - Script for job array tasks:

```bash
#!/bin/bash
# array_task.sh - Script for Slurm job array
# Each array task runs independently with its own SLURM_ARRAY_TASK_ID
echo "Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Array Job ID:  $SLURM_ARRAY_JOB_ID"
echo "Hostname:      $HOSTNAME"
echo "Processing item $SLURM_ARRAY_TASK_ID of $SLURM_ARRAY_TASK_COUNT"
echo "Current time:  $(date)"
sleep 5
echo "Task $SLURM_ARRAY_TASK_ID complete"
```

**05-array/array_batch.sh** - Slurm job array batch script:

```bash
#!/bin/bash

#SBATCH --job-name=array_job
#SBATCH --output=array_%A_%a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:02:00
#SBATCH --array=1-5

./array_task.sh
```

To run:

```bash
# Before: Note empty queue
squeue

cd 05-array
sbatch array_batch.sh

# After: See array tasks
squeue
squeue -r   # Show array tasks expanded

# Check array job outputs after completion
ls -la array_*.out
cat array_*_1.out
cd ..
```

#### Job Arrays Explained

Job arrays allow you to submit multiple similar jobs with a single submission. 
The `--array` directive creates multiple independent tasks from a single batch script.

**--array Syntax:**
- `--array=1-5`      : Create 5 tasks (IDs 1, 2, 3, 4, 5)
- `--array=1,3,5,7`  : Create specific tasks (IDs 1, 3, 5, 7)
- `--array=1-10:2`   : Create tasks with step (IDs 1, 3, 5, 7, 9)
- `--array=1-100%10` : Limit concurrent tasks to 10 at a time

**Environment Variables:**
- `$SLURM_ARRAY_TASK_ID`    : Current task ID (e.g., 1, 2, 3...)
- `$SLURM_ARRAY_JOB_ID`     : Master job ID for the entire array
- `$SLURM_ARRAY_TASK_COUNT` : Total number of tasks in the array

**Output Files:**
- `%A` in filename expands to the array job ID
- `%a` in filename expands to the array task ID
- Example: `array_12345_1.out`, `array_12345_2.out`, etc.

**Use Cases:**
- Parameter sweeps (different input values)
- Processing multiple input files
- Monte Carlo simulations
- Any embarrassingly parallel workload

Check accounting for all simple jobs:

```bash
sacct -u mpiuser
```

#### 3f. OpenMP Hello World

**hello_omp.c** - Hello World with OpenMP threads:

```c
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main() {
    printf("Hello from OpenMP - using %d threads\n", omp_get_max_threads());
    
    #pragma omp parallel
    {
        int tid = omp_get_thread_num();
        int num_threads = omp_get_num_threads();
        char *hostname = getenv("HOSTNAME");
        printf("Hello from thread %d of %d on host %s\n", 
               tid, num_threads, hostname ? hostname : "unknown");
    }
    
    printf("All threads completed\n");
    return 0;
}
```

**hello_omp_batch.sh** - Slurm batch script:

```bash
#!/bin/bash

#SBATCH --job-name=hello_omp
#SBATCH --output=a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:01:00

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
./hello_omp.x
```

To run:

```bash
cd /scratch/mpiuser/OpenMP
gcc -fopenmp -o hello_omp.x hello_omp.c
sbatch hello_omp_batch.sh
squeue
# Check output: cat a.out (shows greeting from each thread)
```

#### 3g. OpenMP Environment

**env_omp.c** - Display OpenMP/Slurm environment from each thread:

```c
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main() {
    printf("=== OpenMP Environment ===\n");
    printf("Max threads:      %d\n", omp_get_max_threads());
    printf("Num processors:   %d\n", omp_get_num_procs());
    printf("Job ID:           %s\n", getenv("SLURM_JOB_ID") ? getenv("SLURM_JOB_ID") : "N/A");
    printf("Job Name:         %s\n", getenv("SLURM_JOB_NAME") ? getenv("SLURM_JOB_NAME") : "N/A");
    printf("Node List:        %s\n", getenv("SLURM_JOB_NODELIST") ? getenv("SLURM_JOB_NODELIST") : "N/A");
    printf("==========================\n\n");
    
    #pragma omp parallel
    {
        #pragma omp critical
        {
            char *hostname = getenv("HOSTNAME");
            char *cpus = getenv("SLURM_JOB_CPUS_PER_NODE");
            printf("Thread %2d: Hostname=%s, CPUs=%s\n",
                   omp_get_thread_num(),
                   hostname ? hostname : "unknown",
                   cpus ? cpus : "N/A");
        }
    }
    
    return 0;
}
```

**env_omp_batch.sh** - Slurm batch script:

```bash
#!/bin/bash

#SBATCH --job-name=env_omp
#SBATCH --output=a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:01:00

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
./env_omp.x
```

To run:

```bash
cd /scratch/mpiuser/OpenMP
gcc -fopenmp -o env_omp.x env_omp.c
sbatch env_omp_batch.sh
squeue
# Check output: cat a.out (shows SLURM_* vars from thread perspective)
```

#### 3h. MPI Hello World

**hello_mpi.c** - Hello World with MPI ranks:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mpi.h>

int main(int argc, char *argv[]) {
    int rank, size, len;
    char hostname[MPI_MAX_PROCESSOR_NAME];
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_processor_name(hostname, &len);
    
    printf("Hello from rank %d of %d on host %s\n", rank, size, hostname);
    
    MPI_Finalize();
    return 0;
}
```

**hello_mpi_batch.sh** - Slurm batch script:

```bash
#!/bin/bash

#SBATCH --job-name=hello_mpi
#SBATCH --output=a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=4
#SBATCH --time=00:01:00

srun --mpi=pmix ./hello_mpi.x
```

To run:

```bash
cd /scratch/mpiuser/MPI
export PATH=/opt/openmpi/5.0.1/bin:$PATH
export LD_LIBRARY_PATH=/opt/openmpi/5.0.1/lib:$LD_LIBRARY_PATH
mpicc -o hello_mpi.x hello_mpi.c
sbatch hello_mpi_batch.sh
squeue
# Check output: cat a.out (shows greeting from each MPI rank)
```

#### 3i. MPI Environment

**env_mpi.c** - Display MPI/Slurm environment from each rank:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mpi.h>

int main(int argc, char *argv[]) {
    int rank, size, len;
    char hostname[MPI_MAX_PROCESSOR_NAME];
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_processor_name(hostname, &len);
    
    if (rank == 0) {
        printf("=== MPI Environment ===\n");
        printf("Total ranks:    %d\n", size);
        printf("Job ID:         %s\n", getenv("SLURM_JOB_ID") ? getenv("SLURM_JOB_ID") : "N/A");
        printf("Job Name:       %s\n", getenv("SLURM_JOB_NAME") ? getenv("SLURM_JOB_NAME") : "N/A");
        printf("Node List:      %s\n", getenv("SLURM_JOB_NODELIST") ? getenv("SLURM_JOB_NODELIST") : "N/A");
        printf("=======================\n\n");
    }
    
    MPI_Barrier(MPI_COMM_WORLD);
    
    printf("Rank %2d of %2d: Hostname=%s, SLURM_PROCID=%s\n",
           rank, size, hostname, getenv("SLURM_PROCID") ? getenv("SLURM_PROCID") : "N/A");
    
    MPI_Finalize();
    return 0;
}
```

**env_mpi_batch.sh** - Slurm batch script:

```bash
#!/bin/bash

#SBATCH --job-name=env_mpi
#SBATCH --output=a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=4
#SBATCH --time=00:01:00

srun --mpi=pmix ./env_mpi.x
```

To run:

```bash
cd /scratch/mpiuser/MPI
export PATH=/opt/openmpi/5.0.1/bin:$PATH
export LD_LIBRARY_PATH=/opt/openmpi/5.0.1/lib:$LD_LIBRARY_PATH
mpicc -o env_mpi.x env_mpi.c
sbatch env_mpi_batch.sh
squeue
# Check output: cat a.out (shows SLURM_* vars from rank perspective)
```

Check accounting for all parallel examples:

```bash
sacct -u mpiuser
```

#### 3j. Queue Filling - Demonstrating squeue and scancel

This example demonstrates how jobs queue up when resources are limited, and how to use `squeue` and `scancel` to manage them.

**06-queue_fill/queue_fill_batch.sh** - A longer-running job (2 minutes):

```bash
#!/bin/bash

#SBATCH --job-name=queue_fill
#SBATCH --output=fill_%j.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:05:00

echo "Queue fill job $SLURM_JOB_ID started at $(date)"
echo "Running on $HOSTNAME"
sleep 120
echo "Queue fill job $SLURM_JOB_ID finished at $(date)"
```

**To demonstrate queue filling:**

```bash
cd /scratch/mpiuser/simple

# Check initial state
echo "=== Initial cluster state ==="
sinfo
squeue

cd 06-queue_fill

# Submit 6 jobs (likely more than available CPUs)
echo "=== Submitting 6 jobs to fill the queue ==="
for i in {1..6}; do
    sbatch queue_fill_batch.sh
done
cd ..

# Watch the queue - some RUNNING, some PENDING
echo "=== Queue state after submissions ==="
squeue

# Show only pending jobs (waiting for resources)
echo "=== Pending jobs (waiting for resources) ==="
squeue -t PENDING

# Show only running jobs
echo "=== Running jobs ==="
squeue -t RUNNING
```

When you submit more jobs than available CPUs, some will go to PENDING state. The output looks like:

```yaml
JOBID  PARTITION  NAME        USER     ST  TIME  NODES  NODELIST(REASON)
101    lcilab     queue_fill  mpiuser  R   0:15  1      lci-compute-01-1
102    lcilab     queue_fill  mpiuser  R   0:15  1      lci-compute-01-2
103    lcilab     queue_fill  mpiuser  R   0:15  1      lci-compute-01-1
104    lcilab     queue_fill  mpiuser  PD  0:00  1      (Resources)
105    lcilab     queue_fill  mpiuser  PD  0:00  1      (Resources)
106    lcilab     queue_fill  mpiuser  PD  0:00  1      (Resources)
```

**Using scancel:**

```bash
# Cancel a specific job
scancel -j 104

# Cancel all jobs with a specific name
scancel -n queue_fill

# Cancel all jobs for a user
scancel -u mpiuser

# Cancel only pending jobs
scancel -t PENDING

# Verify queue is empty
squeue
```

**Key points:**
- When resources are exhausted, new jobs go to PENDING state
- PENDING jobs show reason in `(REASON)` column (e.g., Resources, Priority, Dependencies)
- `scancel` can target specific jobs (`-j`), job names (`-n`), users (`-u`), or states (`-t`)
- Use `squeue -t PENDING` to see only waiting jobs
- Use `squeue -t RUNNING` to see only active jobs

#### 3k. Python Array Job - Parameter Sweep

This example demonstrates processing multiple input files using a Slurm job array with Python.

**07-python_array/process_inputs.py** - Python script to process input files:

```python
#!/usr/bin/env python3
import sys
import os

array_task_id = int(sys.argv[1])
input_file = f"input/{array_task_id}.inp"
output_file = f"output/{array_task_id}.out"

with open(input_file, 'r') as f:
    numbers = [int(x) for x in f.read().split()]

result = sum(numbers)
mean = result / len(numbers)

with open(output_file, 'w') as f:
    f.write(f"Task {array_task_id}: Processed {input_file}\n")
    f.write(f"  Numbers: {numbers}\n")
    f.write(f"  Sum: {result}\n")
    f.write(f"  Mean: {mean:.2f}\n")
```

**07-python_array/generate_inputs.py** - Generate sample input files:

```python
#!/usr/bin/env python3
import os
import random

os.makedirs("input", exist_ok=True)
os.makedirs("output", exist_ok=True)

for i in range(1, 6):
    with open(f"input/{i}.inp", 'w') as f:
        numbers = [random.randint(1, 100) for _ in range(5)]
        f.write(" ".join(map(str, numbers)))
    print(f"Created input/{i}.inp")
```

**07-python_array/python_array_batch.sh** - Slurm batch script:

```bash
#!/bin/bash

#SBATCH --job-name=py_array
#SBATCH --output=slurm_py_array_%A_%a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:05:00
#SBATCH --array=1-5

cd /scratch/mpiuser/simple/07-python_array
python3 process_inputs.py ${SLURM_ARRAY_TASK_ID}
```

To run:

```bash
cd /scratch/mpiuser/simple/07-python_array

# Generate sample input files
python3 generate_inputs.py
ls -la input/

# Submit the array job
sbatch python_array_batch.sh

# Check status
squeue
squeue -r   # Expanded view

# Wait for completion, then check outputs
sleep 10
cat output/*.out
```

#### 3l. R Array Job - Data Processing

This example demonstrates using R with Slurm job arrays for parallel data processing.

**Prerequisite:** R must be installed on all nodes (run as root):

```bash
# Install R on head node
dnf install -y R

# Install R on all compute nodes
clush -g compute "dnf install -y R"
```

**08-R/process_data.R** - R script for data processing:

```r
#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
task_id <- as.integer(args[1])

set.seed(task_id)

data <- rnorm(100, mean = task_id * 10, sd = 5)

result <- list(
  task_id = task_id,
  mean = mean(data),
  sd = sd(data),
  min = min(data),
  max = max(data)
)

output_dir <- "r_output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

output_file <- file.path(output_dir, paste0(task_id, ".out"))

sink(output_file)
cat(sprintf("R Array Task %d Results\n", task_id))
cat("========================\n")
cat(sprintf("Generated %d random numbers\n", length(data)))
cat(sprintf("Mean:   %.2f\n", result$mean))
cat(sprintf("StdDev: %.2f\n", result$sd))
cat(sprintf("Min:    %.2f\n", result$min))
cat(sprintf("Max:    %.2f\n", result$max))
cat(sprintf("Host:   %s\n", Sys.info()["nodename"]))
sink()

cat(sprintf("Task %d complete - output written to %s\n", task_id, output_file))
```

**08-R/r_batch.sh** - Slurm batch script:

```bash
#!/bin/bash

#SBATCH --job-name=r_array
#SBATCH --output=slurm_r_array_%A_%a.out
#SBATCH --partition=lcilab
#SBATCH --ntasks=1
#SBATCH --time=00:05:00
#SBATCH --array=1-5

cd /scratch/mpiuser/simple/08-R
Rscript process_data.R ${SLURM_ARRAY_TASK_ID}
```

To run:

```bash
cd /scratch/mpiuser/simple/08-R

# Submit the array job
sbatch r_batch.sh

# Check status
squeue
squeue -r   # Expanded view

# Wait for completion, then check outputs
sleep 10
cat r_output/*.out

# View Slurm output logs
head slurm_r_array_*.out
```

**Key points:**
- Rscript runs R scripts non-interactively
- Each array task processes independently with unique `$SLURM_ARRAY_TASK_ID`
- Output files are unique per task

Check accounting for all simple jobs:

```bash
sacct -u mpiuser
```

### 4. Cluster resource allocation with `salloc`

**OpenMP run:**


Become user `mpiuser`:

```bash
sudo su - mpiuser
```

Step into OpenMP directory (on /scratch/ which is shared across nodes):
```bash
cd /scratch/mpiuser/OpenMP
```


Run command `salloc` to allocate 2 CPU cores on any of the nodes in the cluster: 

```
salloc -n 2 -p lcilab
```

See the allocated resources:

```bash
squeue 
sinfo -N -l
```

Step into directory OpenMP, setup 2 threads for a run, then run heated_plate_openmp.x:

```bash
cd /scratch/mpiuser/OpenMP
gcc -fopenmp -o heated_plate.x heated_plate_openmp.c -lm
export OMP_NUM_THREADS=2
./heated_plate.x 
```

After the run finishes, exit from salloc, and check the resources:

```bash
exit
sinfo
```

Check the job accounting info for mpiuser:

```bash
sacct -u mpiuser
```

It should show one completed job.

### 5. Using command `srun`

Execute `srun` to allocate two CPUs on the cluster and get a shell on a compute node:

```bash
srun -n 2 -p lcilab --pty bash
```

Notice, you get a shell on one of the compute nodes. Now you can run interactive applications.

```bash
export OMP_NUM_THREADS=2
./heated_plate.x 
```

See how many CPUs the run is utilizing. One CPU is dedicated to bash itself.

Exit from ```srun```:
```bash
exit
```
Run command `sacct` to check out the job accounting again:

```bash 
sacct -u mpiuser
```
Notice two jobs completed, one for interactive run and another for the bash shell.

**MPI runs:**

**Important:** Before running MPI jobs interactively, remove the default stack size limit:

```bash
ulimit -s unlimited
```

This is needed because the MPI example code allocates large arrays on the stack (~8MB). Without this, the jobs will segfault. The batch scripts (`mpi_batch.sh`, `mpi_srun.sh`, `poisson_batch.sh`) already include this command.

Check SLURM support for pmi2 and pmix:

```bash
srun --mpi=list
```
It should show pmi2, mpix, and pmix_4.


Change directory to MPI, and run `mpi_heat2D.x` through `srun` with 4, 6, and 8 processes:

```bash
cd /scratch/mpiuser/MPI
srun --mpi=pmix -n 4 -p lcilab mpi_heat2D.x
srun --mpi=pmix_v4 -n 4 -p lcilab mpi_heat2D.x
```

Run command `sacct` to check out the job accounting:

```bash 
sacct -u mpiuser
```

To launch Open MPI applications using PMIx the '--mpi=pmix' option must be specified on the srun command line or 'MpiDefault=pmix' must be configured in slurm.conf.


### 6. Using submit scripts and command `sbatch`

In directory `/scratch/mpiuser/MPI`, check out submit script `mpi_batch.sh`:

```bash
#!/bin/bash

#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

ulimit -s unlimited
srun --mpi=pmix mpi_heat2D.x
```

Notice, we use `srun --mpi=pmix` (not `mpirun`) so that Slurm handles the process placement and accounting. The batch scripts already include `ulimit -s unlimited` to prevent stack overflow issues.

Submit the script to run with command `sbatch`:

```bash
sbatch mpi_batch.sh
```

Run command `squeue` to see the running job:
```bash
squeue
```

Copy the submit script, ```mpi_batch.sh```, into ```mpi_srun.sh```:
```bash
cp mpi_batch.sh  mpi_srun.sh
```
The modified submit script, mpi_srun.sh, should look as follows:

```bash
#!/bin/bash

#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

ulimit -s unlimited
srun --mpi=pmix mpi_heat2D.x
```

Submit the job to run on the cluster:

```bash
sbatch mpi_srun.sh
```

Check out the stdo output file, slurm-\<job_id\>.out


**OpenMP runs:**

Step into directory OpenMP:

```bash
cd /scratch/mpiuser/OpenMP
```

Check out submit script `openmp_batch.sh`. It runs directly from `/scratch/mpiuser/OpenMP`:

```bash
#!/bin/bash

#SBATCH --job-name=OMP_run
#SBATCH --output=slurm.out
#SBATCH --error=slurm.err
#SBATCH --partition=lcilab
#SBATCH --ntasks-per-node=2

myrun=heated_plate.x                          # executable to run

export OMP_NUM_THREADS=$SLURM_JOB_CPUS_PER_NODE  # assign the number of threads
cd /scratch/mpiuser/OpenMP

./$myrun > run.out-$SLURM_JOB_ID
```


Submit the script to a run on the cluster via command `sbatch`:

```bash
sbatch openmp_batch.sh
```

After the job completes, check out the content of the output file, run.out-\<jobid\>, and the stdo output file slurm.out

### 7. Terminate a job with command `scancel`

Submit the OpenMP job with `sbatch` to run on node `compute2`. Check out its status with command `squeue`.
Terminate the job with command `scancel`:

```bash
sbatch -w lci-compute-01-1 openmp_batch.sh
squeue
scancel -j <jobid>
```


### 8.  Concurrently submitted jobs


If resources are unavailable, jobs will stay in the queue.

Go to the MPI directory:

```bash
cd /scratch/mpiuser/MPI
```

Launch `srun` with bash, and requesting 2 tasks:

```bash
srun -n 2 -p lcilab --pty bash
```

Submit `mpi_batch.sh`:

```bash
sbatch  mpi_batch.sh
```

Run command `squeue`. It should show you that the last job is waiting in the queue due to unavailable resources,
 namely, the CPU cores:
 
```yaml
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                31    lcilab MPI_test  mpiuser PD       0:00      4 (Resources)
                30    lcilab     bash  mpiuser  R       1:38      1 compute1
```

exit from `srun`, and run `squeue` again. The MPI job should begin running.

### 9.  Command sstat

First, set up the OpenMPI environment and compile `poisson_mpi.c`:

```bash
export PATH=/opt/openmpi/5.0.1/bin:$PATH
export LD_LIBRARY_PATH=/opt/openmpi/5.0.1/lib:$LD_LIBRARY_PATH
cd /scratch/mpiuser/MPI
mpicc -o poisson_mpi.x poisson_mpi.c
```

To see the resource utilization of running jobs, use command `sstat`

Submit `poisson_batch.sh`:

```bash
sbatch poisson_batch.sh
```

Run command to see the resource utilization by the running job. 
```bash
sstat -j <jobid>
```

Selected and formatted output for job with, for example, jobid 30:
```bash
sstat -p --format=AveCPU,AvePages,AveRSS,AveVMSize,JobID -j 30
```

```yaml
AveCPU|AvePages|AveRSS|AveVMSize|JobID|
00:02:30|7|57000K|65404K|29.0|
```


### 10. Job accounting information

Command `sacct` can give formatted output.

To get help on the format options, run:

```bash
sacct --helpformat
```

For example,  to get Job ID, Job name, Exit state, start date-time, and end date-time for a job with JobID 8:

```bash
sacct -j 8 --format="JobID,JobName,State,Start,End"
```

Let's review the accounting info for an MPI job, previously submitted with script `mpi_batch.sh`.
Assuming, the JobID was 5:

```bash
sacct -j 61 --format="JobID,JobName,State,NodeList,CPUTime"
```

The output should be similar to below:

```yaml
JobID           JobName      State        NodeList    CPUTime
------------ ---------- ---------- --------------- ----------
61           MPI_test_+    RUNNING lci-compute-01+   00:08:52
61.batch          batch    RUNNING lci-compute-01+   00:04:26
61.0              prted    RUNNING lci-compute-01+   00:08:52
```

The first line shows the total summary for the job with JobID 61.

The second line shows the first step summary, for the batch script submission.

The third line shows the main part related to the mpirun (orted).

If one of the fields don't fit in the output, expand the number of positions in the format option,
 for example to see the full name of the job and the compute nodes, run:
 ```bash
 sacct -j 61 --format="JobID,JobName%15,State,NodeList%20,CPUTime"
 ```
 
 ```yaml
 JobID                JobName      State             NodeList    CPUTime
------------ --------------- ---------- -------------------- ----------
61             MPI_test_case  COMPLETED lci-compute-01-[1-2]   00:32:32
61.batch               batch  COMPLETED     lci-compute-01-1   00:16:16
61.0                   prted  COMPLETED     lci-compute-01-2   00:32:36

 ```

### 11. Command `scontrol`

It allows you to read the information about the SLURM configuration, compute nodes, running jobs and commit modifications and updates at runtime.

For example, to see the information about SLURM configuration:

```bash 
scontrol show config
```

To get the info about a compute node, for example `compute2`:

```bash
scontrol show node lci-compute-01-1
```

To see a detailed information about submitted job, say with jobid #12

```bash 
scontrol show job 12
```

Submit another `openmp_batch.sh` job, and check its information with 
```bash
scontrol show job <jobid>
```
