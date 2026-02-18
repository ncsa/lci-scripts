#include <stdio.h>
#include <omp.h>

#define CHUNKSIZE 100
#define N     1000

int main ()
{

int i, chunk, tid;
float a[N], b[N], c[N];

/* Some initializations */
for (i=0; i < N; i++)
  a[i] = b[i] = i * 1.0;
chunk = CHUNKSIZE;

#pragma omp parallel shared(a,b,c,chunk) private(i)
  {

  #pragma omp for schedule(dynamic,chunk) nowait
  for (i=0; i < N; i++)
   {
     c[i] = a[i] + b[i];

      /* Obtain and print thread id and array index number */
     tid = omp_get_thread_num();
     printf("thread = %d, i = %d\n", tid, i);
   }

  }  /* end of parallel section */

}
