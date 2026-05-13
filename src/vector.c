#include "vector.h"
#include <stdio.h>
#include <stdlib.h>

Vector *create_vector(int size) {
    Vector *vector = (Vector *)malloc(sizeof(Vector));
    vector->size = size;
    vector->data = (complex double *)malloc(size * sizeof(complex double));
    return vector;
}

void free_vector(Vector *vector) {
    if (vector) {
        free(vector->data);
        free(vector);
    }
}

void print_vector(const Vector *vector) {
    for (int i = 0; i < vector->size; i++) {
        printf("%.2f + %.2fi\n", creal(vector->data[i]), cimag(vector->data[i]));
    }
}
