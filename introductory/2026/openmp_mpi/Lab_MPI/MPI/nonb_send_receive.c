/* Non-Blocking Message Passing Routines Example */
#include "mpi.h"
#include <stdio.h>

int main(int argc, char *argv[]) { 
int numRanks, rank, dest, source, tag=222;  
char inmsg[9], outmsg[9]="LCI_2026";
MPI_Status Stat;
MPI_Request request = MPI_REQUEST_NULL;

MPI_Init(&argc,&argv);
MPI_Comm_size(MPI_COMM_WORLD, &numRanks);
MPI_Comm_rank(MPI_COMM_WORLD, &rank);

if (rank == 0) {
  dest = 1;
  MPI_Isend(&outmsg, 9, MPI_CHAR, dest, tag, MPI_COMM_WORLD, &request);
          } 

else if (rank == 1) {
  source = 0;
  MPI_Irecv(&inmsg, 9, MPI_CHAR, source, tag, MPI_COMM_WORLD, &request);
          }

MPI_Wait(&request, &Stat);
if (rank == 1) {
  printf("Rank %d Received %s from Rank %d \n", rank, inmsg, source);
		  }

MPI_Finalize();
}
