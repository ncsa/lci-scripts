
## Lab: Build a Cluster: Run Application via Scheduler

**Objective:** learn SLURM commands to submit, monitor, terminate computational jobs, and check completed job accounting info.

**Note:** All source code and compiled binaries should be run from `/scratch/` (e.g., `/scratch/mpiuser/`), which is the only shared filesystem visible from all compute nodes. The home directory is not mounted on compute nodes.

**Steps:**

- Create accounts and users in SLURM

- Browse the cluster resources with `sinfo`

- Resource allocation via `salloc` for application runs

- Using `srun` for interactive runs

- `sbatch` to submit job scripts 

- Terminate a job with `scancel`

- Concurrently submitted jobs and resources

- Job monitoring with `squeue` and `sstat` commands.

- Job statistics with `sacct` commands

- Command `scontrol show` exercises

- Simple bash script example via `sbatch`

### 1. Create cluster account and users in SLURM

For correct accounting, association, and resource assignments, users and accounts should be created in SLURM.

Accounts in SLURM have the meaning like posix groups in Linux.

We create account (group) lci2024:

```bash
sudo sacctmgr -i add account lci2024 Description="LCI 2024 workshop"
```

We create users `mpiuser` and `rocky` and assign them to cluster "cluster" and account (group) lci2024:

```bash
sudo sacctmgr -i create user name=mpiuser cluster=cluster account=lci2024
sudo sacctmgr -i create user name=rocky cluster=cluster account=lci2024
```

Check the accounts and users:

```bash
sacctmgr list associations format=user,account
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

### 3. Cluster resource allocation with `salloc`

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
salloc -n 2
```

See the allocated resources:

```bash
sinfo
squeue 
sinfo -N -l
```

Step into directory OpenMP, setup 2 threads for a run, then run heated_plate_openmp.x:

```bash
cd /scratch/mpiuser/OpenMP
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

### 4. Using command `srun`

Execute `srun` to allocate two CPUs on the cluster and get a shell on a compute node:

```bash
srun -n 2 --pty bash
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
srun --mpi=pmix -n 4  mpi_heat2D.x
srun --mpi=pmix_v4 -n 4  mpi_heat2D.x
```

Run command `sacct` to check out the job accounting:

```bash 
sacct -u mpiuser
```

To launch Open MPI applications using PMIx the '--mpi=pmix' option must be specified on the srun command line or 'MpiDefault=pmix' must be configured in slurm.conf.


### 5. Using submit scripts and command `sbatch`

In directory `/scratch/mpiuser/MPI`, check out submit script `mpi_batch.sh`:

```bash
#!/bin/bash

#SBATCH --job-name=MPI_test_case
#SBATCH --ntasks-per-node=2
#SBATCH --nodes=2
#SBATCH --partition=lcilab

srun --mpi=pmix mpi_heat2D.x
```

Notice, we use `srun --mpi=pmix` (not `mpirun`) so that Slurm handles the process placement and accounting. The batch scripts already include `ulimit -s unlimited` to prevent stack overflow issues.

Submit the script to run with command `sbatch`:

```bsash
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


Submit the script toa run on the cluster via command `sbatch`:

```bash
sbatch openmp_batch.sh
```

After the job completes, check out the content of the output file, run.out-\<jobid\>, and the stdo output file slurm.out

### 6. Terminate a job with command `scancel`

Submit the OpenMP job with `sbatch` to run on node `compute2`. Check out its status with command `squeue`.
Terminate the job with command `scancel`:

```bash
sbatch -w lci-compute-01-1 openmp_batch.sh
squeue
scancel -j <jobid>
```


### 7.  Concurrently submitted jobs


If resources are unavailable, jobs will stay in the queue.

Go to the MPI directory:

```bash
cd /scratch/mpiuser/MPI
```

Launch `srun` with bash, and requesting 2 tasks:

```bash
srun -n 2 --pty bash
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

### 8.  Command sstat

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


### 9. Job accounting information

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

If one of the firelds don't fit in the output, expand the number of positions in the format option,
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

### 10. Command `scontrol`

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

### 11. Simple bash script example

This section demonstrates submitting a basic bash script via `sbatch`. No MPI or OpenMP is needed for this simple example.

The source files are in `simple/` directory:

**count.sh** - A simple script that counts from 1 to a given number:

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

**count_batch.sh** - The Slurm batch script to submit it:

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

To run this example:

```bash
cd /scratch/mpiuser/simple
cat count.sh
cat count_batch.sh
sbatch count_batch.sh
squeue

# After the job completes, check the output
cat slurm_count.out

# Check job accounting
sacct -u mpiuser
```
