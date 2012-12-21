#include <stdio.h>
#include <stdlib.h>

void printmat(char *name, double *A, int m, int n);
double unif(double lower, double upper);


int main(void)
{
    int i, j, k;
    - m, p, q, n = 2, 3, 4, 5
    - a = Matrix.new 'A', m, p
    - b = Matrix.new 'B', p, q
    - c = Matrix.new 'C', q, n 
    - d = Matrix.new 'D'

    - [a, b, c].each do |var|
      = var.declaration
      = var.malloc


    = puts ((a*b)*(b*c)).inspect

    


    -if false
      - [a, b].each do |var|
        = var.unif_fill -1, 1
        = var.print 

      = (a*b).into ab
      = ab.print
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



