#ifndef VECTOR_H
#define VECTOR_H

#include <cuComplex.h>

typedef struct {
    int size;
    cuDoubleComplex *data;
} Vector;

Vector *create_vector(int size);
void free_vector(Vector *vector);
void print_vector(const Vector *vector);
double vector_dot(const Vector *a, const Vector *b);
Vector *vector_copy(const Vector *vector);
Vector *load_vector_from_csv(const char *filename);

#endif // VECTOR_H