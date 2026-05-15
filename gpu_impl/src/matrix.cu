#include "matrix.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

Matrix *create_matrix(int rows, int cols) {
    Matrix *matrix = (Matrix *)malloc(sizeof(Matrix));
    matrix->rows = rows;
    matrix->cols = cols;
    matrix->data = nullptr;
    cudaMallocManaged(&matrix->data, rows * cols * sizeof(cuDoubleComplex));

    for (int i = 0; i < rows * cols; i++) {
        matrix->data[i] = make_cuDoubleComplex(0, 0);
    }

    return matrix;
}

Matrix *create_identity_matrix(int size) {
    Matrix *matrix = create_matrix(size, size);
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            matrix->data[i * size + j] = (i == j) ? make_cuDoubleComplex(1, 0) : make_cuDoubleComplex(0, 0);
        }
    }
    return matrix;
}

void free_matrix(Matrix *matrix) {
    if (matrix) {
        cudaFree(matrix->data);
        free(matrix);
    }
}

Matrix *matrix_add(const Matrix *a, const Matrix *b) {
    if (a->rows != b->rows || a->cols != b->cols) return NULL; // Incompatible dimensions
    Matrix *result = create_matrix(a->rows, a->cols);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < a->cols; j++) {
            result->data[i * result->cols + j] = cuCadd(a->data[i * a->cols + j], b->data[i * b->cols + j]);
        }
    }
    return result;
}

Matrix *matrix_mul(const Matrix *a, const Matrix *b) {
    if (a->cols != b->rows) return NULL; // Incompatible dimensions
    Matrix *result = create_matrix(a->rows, b->cols);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < b->cols; j++) {
            result->data[i * result->cols + j] = make_cuDoubleComplex(0, 0);
            for (int k = 0; k < a->cols; k++) {
                result->data[i * result->cols + j] = cuCadd(result->data[i * result->cols + j], cuCmul(a->data[i * a->cols + k], b->data[k * b->cols + j]));
            }
        }
    }
    return result;
}

Matrix *matrix_scalar_mul(const Matrix *matrix, cuDoubleComplex scalar) {
    Matrix *result = create_matrix(matrix->rows, matrix->cols);
    for (int i = 0; i < matrix->rows; i++) {
        for (int j = 0; j < matrix->cols; j++) {
            result->data[i * matrix->cols + j] = cuCmul(matrix->data[i * matrix->cols + j], scalar);
        }
    }
    return result;
}

void print_matrix(const Matrix *matrix) {
    for (int i = 0; i < matrix->rows; i++) {
        for (int j = 0; j < matrix->cols; j++) {
            printf("%.2f + %.2fi ", matrix->data[i * matrix->cols + j].x, matrix->data[i * matrix->cols + j].y);
        }
        printf("\n");
    }
}

Matrix *matrix_dot(const Matrix *a, const Matrix *b) {
    if (a->cols != b->cols || a->rows != b->rows) return NULL; // Incompatible dimensions
    Matrix *result = create_matrix(a->rows, a->cols);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < a->cols; j++) {
            result->data[i * result->cols + j] = cuCmul(a->data[i * a->cols + j], b->data[i * b->cols + j]);
        }
    }
    return result;
}

Matrix *matrix_transpose_conjugate(const Matrix *matrix) {
    Matrix *result = create_matrix(matrix->cols, matrix->rows);
    for (int i = 0; i < matrix->rows; i++) {
        for (int j = 0; j < matrix->cols; j++) {
            result->data[j * result->cols + i] = cuConj(matrix->data[i * matrix->cols + j]);
        }
    }
    return result;
}

Vector *matrix_vector_mul(const Matrix *matrix, const Vector *vector) {
    if (matrix->cols != vector->size) return NULL; // Incompatible dimensions
    Vector *result = create_vector(matrix->rows);
    for (int i = 0; i < matrix->rows; i++) {
        result->data[i] = make_cuDoubleComplex(0, 0);
        for (int j = 0; j < matrix->cols; j++) {
            result->data[i] = cuCadd(result->data[i], cuCmul(matrix->data[i * matrix->cols + j], vector->data[j]));
        }
    }
    return result;
}

Matrix *matrix_copy(const Matrix *matrix) {
    Matrix *copy = create_matrix(matrix->rows, matrix->cols);
    for (int i = 0; i < matrix->rows * matrix->cols; i++) {
        copy->data[i] = matrix->data[i];
    }
    return copy;
}

Matrix *load_from_csv(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (!file) return NULL;

    int rows = 0;
    int cols = 0;
    char line_buffer[32000];

    // determine dimensions of our matrix
    while (fgets(line_buffer, sizeof(line_buffer), file)) {
        if (rows == 0) {
            char *token = strtok(line_buffer, ",");
            while (token) {
                cols++;
                token = strtok(NULL, ",");
            }
        }
        rows++;
    }

    rewind(file);

    if (rows == 0 || cols == 0) {
        fclose(file);
        return NULL; // Empty file
    }

    // allocate matrix
    Matrix *matrix = create_matrix(rows, cols);
    int i = 0;
    // read data into matrix
    while (fgets(line_buffer, sizeof(line_buffer), file)) {
        int j = 0;
        char *token = strtok(line_buffer, ",");
        while (token) {
            double real, imag;
            sscanf(token, "%lf%lf", &real, &imag);
            cuDoubleComplex value = make_cuDoubleComplex(real, imag);
            matrix->data[i * matrix->cols + j] = value;

            token = strtok(NULL, ",");
            j++;
        }
        i++;
    }

    fclose(file);
    return matrix;
}