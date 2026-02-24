<br><br><br><br>

# Lab: Introduction to OpenMP and MPI.  



**Objective:** 

- Install MPI (OpenMPI) on the cluster.

- Create `mpiuser` account with home directory on the NFS shared file system.

- Compile applications with openmp, and run with different number of threads on a single node.

- Performance scalability of openmp computations.

- Compile and run MPI applications.




***
### Clone and prepare the repo

```bash
git clone https://github.com/ncsa/lci-scripts.git
cd lci-scripts/introductory/2026/openmp_mpi/Lab_MPI/Ansible
```

edit `hosts.ini` and replace the XX with your cluster number

### Compile and install MPI on the cluster

```bash
ansible-playbook install_mpi.yml
```

Test to make sure it installed correctly
```bash
/usr/lib64/openmpi/bin/ompi_info --version
````
MPI needs to be compiled with PMIx support in order to integrate with SLURM scheduler.
We will not be doing that, because it's a much more difficult process. Don't install directly via `dnf` on your own cluster.

- The version is older than you can get otherwise

- PMIx isn't supported

- It won't be optimized for your hardware

***

### Setup user account and files for OpenMP and MPI exercises.

Create user mpiuser on the cluster.
```bash
ansible-playbook setup_mpiuser.yml
```

Copy folders with OpenMP and MPI exercises into mpiuser home directory:
```bash
cd ..
# You should now be in the lci-scripts repo in the Lab_MPI directory
sudo cp -a OpenMP /head/NFS/mpiuser/
sudo cp -a MPI /head/NFS/mpiuser/
chown -R mpiuser:mpiuser /head/NFS/mpiuser
```

Become `mpiuser`:

```bash
sudo su - mpiuser
```
All the exercises below should be done as user `mpiuser`.



***
### Compilation and runs with OpenMP 

SSH to the first compute node:
```bash
ssh lci-compute-XX-1
```

Step into directory OpenMP:

```bash
cd OpenMP
```

- Compile `hello.c` with OpenMP libraries:

```bash
gcc -fopenmp -o hello.x hello.c
```

Run command `ldd` on the generated executable to see the dynamic libraries it is using:

```bash
ldd hello.x
```

It shows the following:

```{admonition} output:
linux-vdso.so.1 (0x00007fffdb8f7000)
libgomp.so.1 => /lib64/libgomp.so.1 (0x00007f6cd3717000)
libc.so.6 => /lib64/libc.so.6 (0x00007f6cd3400000)
/lib64/ld-linux-x86-64.so.2 (0x00007f6cd3765000)
```
Notice `libgomp.so.1` shared object library. 
Executables compiled with OpenMP support always have this loaded.

Now run executable `hello.x` and see what happens:

```bash
./hello.x
```

The output comes with two threads. 
By default, when you run an executable compiled with the openmp support, the number of threads becomes equal to the number of the CPU cores available on the system.

Define environment variable OMP_NUM_THREADS=16, then run the executable again:

```bash
export OMP_NUM_THREADS=16
./hello.x
```

- Compile `for.c` and run executable `for.x` several times:

```bash
gcc -fopenmp -o for.x for.c
./for.x
```
Notice the order of the thread output change if you run ./for.x multiple times.

- Compile `sections.c`:
```bash
gcc -fopenmp -o sections.x sections.c
```

Set the number of threads to 2, and run the executable:

```bash
export OMP_NUM_THREADS=2
./sections.x
```

- Compile `reduction.c`, and execute on 4 threads:

```bash
gcc -fopenmp -o reduction.x reduction.c
export OMP_NUM_THREADS=4
./reduction.x
```

- Compile sum.c with the -fopenmp and run executable across 2 threads:

```bash
export  OMP_NUM_THREADS=2
gcc   -fopenmp   -o sum.x  sum.c
./sum.x
```

Modify file `sum.c` and comment the line with construct `pragma omp critical`:

```c
#include <omp.h>
#include <stdio.h>

int main() {
    double a[1000000];
    int i;
    double sum;

    sum=0;

    #pragma omp parallel for 
    for (i=0; i<1000000; i++) a[i]=i;
    #pragma omp parallel for shared (sum) private (i) 
    for ( i=0; i < 1000000; i++) {
//       #pragma omp critical 
        sum = sum + a[i];
    }
    printf("sum=%lf\n",sum);
}


```


Recompile it again and run several times. Notice the different output results.


### Performance demonstration with OpenMP

Compile the code for solving the steady state heat equation, `heated_plate_openmp.c`:
```bash
gcc -fopenmp -o heated_plate.x heated_plate_openmp.c -lm
```

Open another terminal on your laptop and ssh to the cluster.
Run command `top` on the head node, then hit keys **1 H t**.

While `top` is running, in the original terminal, run `heated_plate.x` with one thread:

```bash
export OMP_NUM_THREADS=1
./heated_plate.x
```

During the runtime, notice the resource utilization in the `top`: one CPU core being utilized at 100%, essentially by one process, `heated_plate.x`:

```yaml
%Cpu0  :   0.0/0.0     0[                                                                                 ]
%Cpu1  : 100.0/0.0   100[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||]
MiB Mem :   7685.5 total,   6449.9 free,    207.3 used,   1028.3 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   7196.2 avail Mem

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 342198 mpiuser   20   0   18272   6028   2096 R  99.9   0.1   0:11.97 heated_plate.x
```

After the run completes, it prints out the Wallclock time of about 49 seconds.

Increase the number of the openmp threads to 2 and run the code again:
```bash
export OMP_NUM_THREADS=2
./heated_plate.x
```

During the runtime, the `top` shows the both CPU core utilization at 100% by two threads:

```yaml
%Cpu0  :  98.7/0.3    99[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| ]
%Cpu1  :  99.0/1.0   100[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||]
MiB Mem :   7685.5 total,   6447.7 free,    208.0 used,   1029.8 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   7194.7 avail Mem
```

After the run completes, Wallclock time shows up at about 25 sec.

Exit `top` with **q** key stroke.

***
### Setup mpiuser environment for MPI

Assuming the MPI compilation and installation on the cluster is completed, exit from compute the node.

Setup environment variables for MPI by placing the snipped below into .bashrc file of `mpiuser`:

```yaml
export MPI_HOME=export MPI_HOME=/usr/lib64/openmpi
export PATH=$PATH:$MPI_HOME/bin
```

Run

```bash
source .bashrc
```


***
### Test mpirun

Step into directory MPI
```bash
cd 
cd MPI
```

Edit `nodes.txt` and replace the XX with the appropriate number.

Verify that `mpirun` works:

```bash
mpirun -n 4 -hostfile nodes.txt uname -n
```

If it works, it should have every compute node to print out its host name twice.

File `nodes.txt` contains the list of the compute nodes and the number of CPU cores on each node:

```c
lci-compute-XX-1 slots=2
lci-compute-XX-2 slots=2
```

***
### Compile and run MPI applications

Compile `hello.c` and run on 4 CPU cores:

```bash
mpicc -o hello.x hello.c
mpirun -n 4 -hostfile nodes.txt hello.x
```

Compile `b_send_receive.x` and run on 2 CPU cores:

```bash
mpicc -o b_send_receive.x b_send_receive.c
mpirun -n 2 -hostfile nodes.txt b_send_receive.x
```

Same with `nonb_send_receive.c`:

```bash
mpicc -o nonb_send_receive.x nonb_send_receive.c
mpirun -n 2 -hostfile nodes.txt nonb_send_receive.x
```

Compile `mpi_reduce.c` and run on 4 processors:

```bash
mpicc -o mpi_reduce.x mpi_reduce.c 
mpirun -n 4 -hostfile nodes.txt mpi_reduce.x
```

Compile `mpi_heat2D.c` and run it on 4 CPU cores.

```bash
mpicc -o mpi_heat2D.x mpi_heat2D.c
mpirun -n 4 -hostfile nodes.txt mpi_heat2D.x
```
