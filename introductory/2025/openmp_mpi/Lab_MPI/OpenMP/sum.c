#include <omp.h>
#include <stdio.h>

int main() {
    double a[1000000];
    int i;
    double sum;

    sum=0;

    #pragma omp parallel for 
    for (i=0; i<1000000; i++) a[i]=i;
    #pragma omp parallel for shared (sum) private (i) 
    for ( i=0; i < 1000000; i++) {
       #pragma omp critical 
        sum = sum + a[i];
    }
    printf("sum=%lf\n",sum);
}
