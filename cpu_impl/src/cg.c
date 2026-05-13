#include "cg.h"
#include <math.h>

Vector *compute(const Matrix *H, const Vector *y, const double sigma_sq, const int iterations) {
    // Precomputation
    int K = H->cols;
    Matrix *identity = create_identity_matrix(K);
    Matrix *a = matrix_add(matrix_mul(matrix_transpose_conjugate(H), H), matrix_scalar_mul(identity, sigma_sq));
    Vector *b = matrix_vector_mul(matrix_transpose_conjugate(H), y);

    free_matrix(identity);

    // Initialize
    Vector *x = create_vector(K);
    Vector *r = vector_copy(b);
    Vector *p = vector_copy(b);

    double rsold = vector_dot(r, r);

    for (int it = 0; it < iterations; it++) {
        Vector *Ap = matrix_vector_mul(a, p);
        // alpha = rsold / (p'*Ap);
        double alpha = rsold / vector_dot(p, Ap);

        for (int i = 0; i < K; i++) {
            x->data[i] += alpha * p->data[i];
            r->data[i] -= alpha * Ap->data[i];
        }

        double rsnew = vector_dot(r, r);
        if (sqrt(rsnew) < TOL) {
            free_vector(Ap);
            break;
        }

        double beta = rsnew / rsold;
        for (int i = 0; i < K; i++) {
            p->data[i] = r->data[i] + beta * p->data[i];
        }

        rsold = rsnew;
        free_vector(Ap);
    }

    free_vector(r);
    free_vector(p);
    free_matrix(a);
    free_vector(b);

    return x;
}