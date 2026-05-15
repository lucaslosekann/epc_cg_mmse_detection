#include "vector.h"
#include <complex.h>
#include <cuda_runtime_api.h>
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>

Vector *create_vector(int size) {
    Vector *vector = (Vector *)malloc(sizeof(Vector));
    vector->size = size;
    vector->data = nullptr;
    cudaMallocManaged(&vector->data, size * sizeof(cuDoubleComplex));
    for (int i = 0; i < size; i++) {
        vector->data[i] = make_cuDoubleComplex(0, 0);
    }
    return vector;
}

void free_vector(Vector *vector) {
    if (vector) {
        cudaFree(vector->data);
        free(vector);
    }
}

void print_vector(const Vector *vector) {
    // cuDoubleComplex *host_data = (cuDoubleComplex *)malloc(vector->size * sizeof(cuDoubleComplex));
    // cudaMemcpy(host_data, vector->data, vector->size * sizeof(cuDoubleComplex), cudaMemcpyDeviceToHost);
    for (int i = 0; i < vector->size; i++) {
        printf("%lf + %lfi\n", cuCreal(vector->data[i]), cuCimag(vector->data[i]));
    }
}

double vector_dot(const Vector *a, const Vector *b) {
    if (a->size != b->size) return 0; // Incompatible dimensions
    double result = 0;
    for (int i = 0; i < a->size; i++) {
        result += cuCreal(cuCmul(a->data[i], cuConj(b->data[i])));
    }
    return result;
}

Vector *vector_copy(const Vector *vector) {
    Vector *copy = create_vector(vector->size);
    for (int i = 0; i < vector->size; i++) {
        copy->data[i] = vector->data[i];
    }
    return copy;
}

Vector *load_vector_from_csv(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (!file) return NULL;

    int size = 0;
    char line_buffer[32000];
    while (fgets(line_buffer, sizeof(line_buffer), file)) {
        size++;
    }
    rewind(file);

    Vector *vector = create_vector(size);
    int index = 0;
    while (fgets(line_buffer, sizeof(line_buffer), file)) {
        double real, imag;
        sscanf(line_buffer, "%lf%lf", &real, &imag);
        vector->data[index++] = make_cuDoubleComplex(real, imag);
    }

    fclose(file);
    return vector;
}