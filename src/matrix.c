#include "matrix.h"
#include <stdio.h>
#include <stdlib.h>

Matrix *create_matrix(int rows, int cols) {
    Matrix *matrix = (Matrix *)malloc(sizeof(Matrix));
    matrix->rows = rows;
    matrix->cols = cols;
    matrix->data = (complex double *)malloc(rows * cols * sizeof(complex double));
    return matrix;
}

void free_matrix(Matrix *matrix) {
    if (matrix) {
        free(matrix->data);
        free(matrix);
    }
}

Matrix *matrix_mul(const Matrix *a, const Matrix *b) {
    if (a->cols != b->rows) return NULL; // Incompatible dimensions
    Matrix *result = create_matrix(a->rows, b->cols);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < b->cols; j++) {
            result->data[i * result->cols + j] = 0;
            for (int k = 0; k < a->cols; k++) {
                result->data[i * result->cols + j] += a->data[i * a->cols + k] * b->data[k * b->cols + j];
            }
        }
    }
    return result;
}

void print_matrix(const Matrix *matrix) {
    for (int i = 0; i < matrix->rows; i++) {
        for (int j = 0; j < matrix->cols; j++) {
            printf("%.2f + %.2fi ", creal(matrix->data[i * matrix->cols + j]), cimag(matrix->data[i * matrix->cols + j]));
        }
        printf("\n");
    }
}

Matrix *matrix_dot(const Matrix *a, const Matrix *b) {
    if (a->cols != b->cols || a->rows != b->rows) return NULL; // Incompatible dimensions
    Matrix *result = create_matrix(a->rows, a->cols);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < a->cols; j++) {
            result->data[i * result->cols + j] = a->data[i * a->cols + j] * b->data[i * b->cols + j];
        }
    }
    return result;
}

Matrix *matrix_transpose(const Matrix *matrix) {
    Matrix *result = create_matrix(matrix->cols, matrix->rows);
    for (int i = 0; i < matrix->rows; i++) {
        for (int j = 0; j < matrix->cols; j++) {
            result->data[j * result->cols + i] = matrix->data[i * matrix->cols + j];
        }
    }
    return result;
}

Matrix *matrix_vector_mul(const Matrix *matrix, const Vector *vector) {
    if (matrix->cols != vector->size) return NULL; // Incompatible dimensions
    Matrix *result = create_matrix(matrix->rows, 1);
    for (int i = 0; i < matrix->rows; i++) {
        result->data[i] = 0;
        for (int j = 0; j < matrix->cols; j++) {
            result->data[i] += matrix->data[i * matrix->cols + j] * vector->data[j];
        }
    }
    return result;
}

Matrix *load_from_csv(const char *filename) {}