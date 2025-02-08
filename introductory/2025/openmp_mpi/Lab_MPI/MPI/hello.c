#include "mpi.h"
#include <stdio.h>

int main(int argc, char *argv[]) {
   int  numtasks, rank, len, rc; 
   char hostname[MPI_MAX_PROCESSOR_NAME];

          // initialize MPI  
   MPI_Init(&argc, &argv);

           // get MPI process rank, size, and processor name
   MPI_Comm_size(MPI_COMM_WORLD, &numtasks);
   MPI_Comm_rank(MPI_COMM_WORLD, &rank);
   MPI_Get_processor_name(hostname, &len); 
   printf ("Number of tasks= %d My rank= %d Running on %s \n", numtasks,rank, hostname);
        // Now can do some computing and message passing ….  
        // done with MPI  
   MPI_Finalize(); 
}

