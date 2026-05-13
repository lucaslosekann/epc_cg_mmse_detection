#include "cg.h"
#include "matrix.h"
#include <stdio.h>
#include <time.h>

#define MAX_ITER 20
// #define SIGMA_SQ 33.6 //128
// #define SIGMA_SQ 268.8 // 1024
#define SIGMA_SQ 537.6 // 2048

int main() {
    Matrix *H = load_from_csv("data/H_2048.csv");
    Vector *y = load_vector_from_csv("data/y_2048.csv");

    clock_t start, end;
    double cpu_time_used;
    start = clock();

    Vector *x = compute(H, y, SIGMA_SQ, MAX_ITER);

    end = clock();
    cpu_time_used = ((double)(end - start)) / CLOCKS_PER_SEC;
    print_vector(x);

    printf("Time taken: %f seconds\n", cpu_time_used);

    // free_matrix(H);
    // free_vector(y);
    // free_vector(x);
    return 0;
}