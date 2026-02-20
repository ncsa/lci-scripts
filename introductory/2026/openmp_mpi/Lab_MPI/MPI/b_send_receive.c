/* Blocking Message Passing Routines Example */
#include "mpi.h"
#include <stdio.h>

int main(int argc, char *argv[]) { 
int numRanks, rank, dest, source, rc, count, tag=222;  
char inmsg[9], outmsg[9]="LCI_2026";
MPI_Status Stat;

MPI_Init(&argc,&argv);
MPI_Comm_size(MPI_COMM_WORLD, &numRanks);
MPI_Comm_rank(MPI_COMM_WORLD, &rank);

if (rank == 0) {
  dest = 1;
  MPI_Send(&outmsg, 9, MPI_CHAR, dest, tag, MPI_COMM_WORLD);
          } 

else if (rank == 1) {
  source = 0;
  MPI_Recv(&inmsg, 9, MPI_CHAR, source, tag, MPI_COMM_WORLD, &Stat);
  printf("Rank %d Received %s from Rank %d \n", rank, inmsg, source);  
  MPI_Get_count(&Stat, MPI_CHAR, &count);
printf("Task %d: Received %d char(s) from task %d with tag %d \n",
       rank, count, Stat.MPI_SOURCE, Stat.MPI_TAG);

		  }
MPI_Finalize();
}
