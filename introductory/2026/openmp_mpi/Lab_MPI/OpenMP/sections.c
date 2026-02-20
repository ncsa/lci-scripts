#include <omp.h>
#include <stdio.h>

#define N     1000

int main ()
{

int i, tid;
float a[N], b[N], c[N], d[N];

/* Some initializations */
for (i=0; i < N; i++) {
  a[i] = i * 1.5;
  b[i] = i + 22.35;
  }

#pragma omp parallel shared(a,b,c,d) private(i)
  {

  #pragma omp sections nowait
   {

    #pragma omp section
    {
    for (i=0; i < N; i++)
      c[i] = a[i] + b[i];
      /* Obtain and print thread id and array index number */
      tid = omp_get_thread_num();
      printf("thread = %d, i = %d\n", tid, i);
    }

    #pragma omp section
    {
    for (i=0; i < N; i++)
      d[i] = a[i] * b[i];
      /* Obtain and print thread id and array index number */
      tid = omp_get_thread_num();
      printf("thread = %d, i = %d\n", tid, i);
    }


   }  /* end of sections */

  }  /* end of parallel section */

}
