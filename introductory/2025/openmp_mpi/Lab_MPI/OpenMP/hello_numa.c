#define _GNU_SOURCE
#include <sched.h>
#include <omp.h>
#include <stdio.h>

int main ()  {

int nthreads, tid, cpu_id;

/* Fork a team of threads with each thread having a private tid variable */
#pragma omp parallel private(tid, cpu_id)
  {

  /* Obtain and print thread id */
  tid = omp_get_thread_num();
  cpu_id = sched_getcpu();
  printf("Hello NUMA from thread = %d, from CPU Core = %d\n", tid, cpu_id);

  /* Only master thread does this */
  if (tid == 0)
    {
    nthreads = omp_get_num_threads();
    printf("Number of threads = %d\n", nthreads);
    }

  }  /* All threads join master thread and terminate */

}

