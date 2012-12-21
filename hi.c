#include <stdio.h>
#include <stdlib.h>
void printmat(char *name, double *A, int m, int n);
double unif(double lower, double upper);
int main(void)
{
    int i, j, k;
    double *A;
    A = malloc(6 * sizeof (*A));
    double *B;
    B = malloc(12 * sizeof (*B));
    double *C;
    C = malloc(20 * sizeof (*C));
    double *D;
    D = malloc(10 * sizeof (*D));
}
double unif(double lower, double upper) {
  return lower + ((upper - lower)*rand())/RAND_MAX;
}
void printmat(char *name, double *A, int m, int n) {
  int i, j;
  printf("%s = [...\n", name);
  for (i = 0; i < m; i++) {
    for (j = 0; j < n; j++)
      printf(" % 7.3f", A[i+j*m]);
    printf(",\n");
  }
  printf("];\n");
}
