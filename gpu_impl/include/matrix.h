#ifndef MATRIX_H
#define MATRIX_H

#include "vector.h"
#include <complex.h>
#include <cuComplex.h>

typedef struct {
    int rows;
    int cols;
    cuDoubleComplex *data;
} Matrix;

Matrix *create_matrix(int rows, int cols);
Matrix *create_identity_matrix(int size);
Matrix *load_from_csv(const char *filename);
void free_matrix(Matrix *matrix);
Matrix *matrix_add(const Matrix *a, const Matrix *b);
Matrix *matrix_mul(const Matrix *a, const Matrix *b);
Matrix *matrix_scalar_mul(const Matrix *matrix, cuDoubleComplex scalar);
void print_matrix(const Matrix *matrix);

Matrix *matrix_dot(const Matrix *a, const Matrix *b);
Matrix *matrix_transpose_conjugate(const Matrix *matrix);

Matrix *matrix_copy(const Matrix *matrix);

// matvec

Vector *matrix_vector_mul(const Matrix *matrix, const Vector *vector);

#endif // MATRIX_H