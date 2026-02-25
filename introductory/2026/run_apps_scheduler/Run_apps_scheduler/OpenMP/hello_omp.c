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
