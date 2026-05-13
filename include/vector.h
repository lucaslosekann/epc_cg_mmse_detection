#ifndef VECTOR_H
#define VECTOR_H

#include <complex.h>

typedef struct {
    int size;
    complex double *data;
} Vector;

Vector *create_vector(int size);
void free_vector(Vector *vector);
void print_vector(const Vector *vector);

#endif // VECTOR_H