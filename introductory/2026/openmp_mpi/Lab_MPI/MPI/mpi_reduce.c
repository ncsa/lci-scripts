#include "mpi.h"
#include <stdio.h>

#define SIZE 16 

int main(int argc, char *argv[]) { 
int numprocs, rank,  i;   
float A[SIZE]={100.2, 0.5, 0.7, 0.5, 0.7, 0.34, 0.23, 0.12, 0.56, 0.55, 0.11, 0.3, 0.45, 0.23, 0.45, 0.11};
float B[SIZE]={0.12, 0.51, 0.17, 0.35, 0.9, 0.37, 0.13, 0.42, 0.86, 0.55, 0.21, 0.6, 0.25, 0.27, 0.45, 0.13};
float part_sum = 0.0, sum;

MPI_Init(&argc,&argv);
MPI_Comm_size(MPI_COMM_WORLD, &numprocs);
MPI_Comm_rank(MPI_COMM_WORLD, &rank);

int chunk = SIZE/numprocs;  

for (i=rank*chunk; i < (rank+1)*chunk; ++i)
    part_sum += A[i] * B[i];

MPI_Reduce(&part_sum, &sum, 1, MPI_FLOAT, MPI_SUM, 0, MPI_COMM_WORLD);
if (rank == 0) 
  printf("Rank %d Total sum from Reduction %f Number of tasks %d \n", rank, sum, numprocs);

MPI_Finalize();
}
