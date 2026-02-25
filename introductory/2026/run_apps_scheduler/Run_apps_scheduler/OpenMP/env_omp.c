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
