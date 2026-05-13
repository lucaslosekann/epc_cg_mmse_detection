#ifndef MATRIX_H
#define MATRIX_H

#include "vector.h"
#include <complex.h>

typedef struct {
    int rows;
    int cols;
    complex double *data;
} Matrix;

Matrix *create_matrix(int rows, int cols);
Matrix *load_from_csv(const char *filename);
void free_matrix(Matrix *matrix);
Matrix *matrix_mul(const Matrix *a, const Matrix *b);
void print_matrix(const Matrix *matrix);

Matrix *matrix_dot(const Matrix *a, const Matrix *b);
Matrix *matrix_transpose(const Matrix *matrix);

// matvec

Matrix *matrix_vector_mul(const Matrix *matrix, const Vector *vector);

#endif // MATRIX_H