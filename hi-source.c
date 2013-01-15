#include <stdio.h>
#include <stdlib.h>

void printmat(char *name, double *A, int m, int n);
double unif(double lower, double upper);


int main(void)
{
    int i, j, k;
    - m, p, q, n = 3, 4, 10, 3 
    - a = Matrix.new 'A', m, p
    - b = Matrix.new 'B', p, q
    - c = Matrix.new 'C', q, n 
    - d = Matrix.new 'D', m, n
    - e = Matrix.new 'E'

    - [a, b, c, d].each do |var|
      = var.init

    - [a, b, c, d].each do |var|
      = var.unif_fill -1, 1
      = var.display 

    = (d * d * (d + (a * b * c * d) + d)).into(e)
    = e.display
}


double unif(double lower, double upper) {
  return lower + ((upper - lower)*rand())/RAND_MAX;
}


void printmat(char *name, double *A, int m, int n) {
  int i, j;

  printf("%s = [...\n", name);
  for (i = 0; i < m; i++) {
    for (j = 0; j < n; j++)
      printf(" % 8.4f", A[i+j*m]);
    printf(",\n");
  }
  printf("];\n");
}
