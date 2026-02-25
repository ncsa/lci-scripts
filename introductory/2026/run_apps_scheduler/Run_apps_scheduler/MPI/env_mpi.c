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
