#include "cg.h"
#include <math.h>

// Matrix *identity = create_identity_matrix(K);
// Matrix *a = matrix_add(matrix_mul(matrix_transpose_conjugate(H), H), matrix_scalar_mul(identity, sigma_sq));
__global__ void compute_A_kernel(const cuDoubleComplex *H, cuDoubleComplex *A, int rows, int cols, double sigma_sq) {
    int i = blockIdx.y * blockDim.y + threadIdx.y; // Row of A
    int j = blockIdx.x * blockDim.x + threadIdx.x; // Col of A

    if (i < cols && j < cols) {
        cuDoubleComplex sum = make_cuDoubleComplex(0.0, 0.0);
        for (int k = 0; k < rows; k++) {
            cuDoubleComplex h_ki = H[k * cols + i];
            cuDoubleComplex h_kj = H[k * cols + j];
            // sum += conj(H_{k,i}) * H_{k,j}
            sum = cuCadd(sum, cuCmul(cuConj(h_ki), h_kj));
        }
        if (i == j) {
            sum = cuCadd(sum, make_cuDoubleComplex(sigma_sq, 0.0));
        }
        A[i * cols + j] = sum;
    }
}

//  matrix_vector_mul(matrix_transpose_conjugate(H), y);
__global__ void compute_b_kernel(const cuDoubleComplex *H, const cuDoubleComplex *y, cuDoubleComplex *b, int rows, int cols) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < cols) {
        cuDoubleComplex sum = make_cuDoubleComplex(0.0, 0.0);
        for (int k = 0; k < rows; k++) {
            cuDoubleComplex h_ki = H[k * cols + i];
            sum = cuCadd(sum, cuCmul(cuConj(h_ki), y[k]));
        }
        b[i] = sum;
    }
}

__global__ void dot_product_kernel(const cuDoubleComplex *a, const cuDoubleComplex *b, double *result, int size) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < size) {
        atomicAdd(result, cuCreal(cuCmul(a[i], cuConj(b[i]))));
    }
}

__global__ void matvec_kernel(const cuDoubleComplex *A, const cuDoubleComplex *p, cuDoubleComplex *Ap, int cols) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < cols) {
        cuDoubleComplex sum = make_cuDoubleComplex(0.0, 0.0);
        for (int j = 0; j < cols; j++) {
            sum = cuCadd(sum, cuCmul(A[i * cols + j], p[j]));
        }
        Ap[i] = sum;
    }
}

__global__ void update_x_r_kernel(cuDoubleComplex *x, cuDoubleComplex *r, const cuDoubleComplex *p, const cuDoubleComplex *Ap, double alpha, int size) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < size) {
        x[i] = cuCadd(x[i], cuCmul(make_cuDoubleComplex(alpha, 0.0), p[i]));
        r[i] = cuCsub(r[i], cuCmul(make_cuDoubleComplex(alpha, 0.0), Ap[i]));
    }
}

__global__ void update_p_kernel(cuDoubleComplex *p, const cuDoubleComplex *r, double beta, int size) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < size) {
        p[i] = cuCadd(r[i], cuCmul(make_cuDoubleComplex(beta, 0), p[i]));
    }
}

Vector *compute(const Matrix *H, const Vector *y, const double sigma_sq, const int iterations) {
    int rows = H->rows;
    int cols = H->cols;
    int K = cols;

    Matrix *a = create_matrix(cols, cols);
    Vector *b = create_vector(cols);
    Vector *Ap = create_vector(cols);

    double *dot_result;
    cudaMalloc(&dot_result, sizeof(double));

    dim3 block_2d(16, 16);
    dim3 grid_2d((H->cols + 15) / 16, (cols + 15) / 16);
    compute_A_kernel<<<grid_2d, block_2d>>>(H->data, a->data, rows, cols, sigma_sq);

    int threads = 256;
    int blocks = (cols + threads - 1) / threads;
    compute_b_kernel<<<blocks, threads>>>(H->data, y->data, b->data, rows, cols);
    cudaDeviceSynchronize(); // Wait for the GPU to finish

    Vector *x = create_vector(K);
    Vector *r = vector_copy(b);
    Vector *p = vector_copy(b);

    cudaMemset(dot_result, 0, sizeof(double));
    dot_product_kernel<<<blocks, threads>>>(r->data, r->data, dot_result, K);
    double rsold = 0;
    cudaMemcpy(&rsold, dot_result, sizeof(double), cudaMemcpyDeviceToHost);

    for (int i = 0; i < iterations; i++) {
        matvec_kernel<<<blocks, threads>>>(a->data, p->data, Ap->data, cols);

        // double alpha = rsold / vector_dot(p, Ap);
        cudaMemset(dot_result, 0, sizeof(double));
        dot_product_kernel<<<blocks, threads>>>(p->data, Ap->data, dot_result, K);
        double pAp = 0;
        cudaMemcpy(&pAp, dot_result, sizeof(double), cudaMemcpyDeviceToHost);
        double alpha = rsold / pAp;

        update_x_r_kernel<<<blocks, threads>>>(x->data, r->data, p->data, Ap->data, alpha, K);

        cudaMemset(dot_result, 0, sizeof(double));
        dot_product_kernel<<<blocks, threads>>>(r->data, r->data, dot_result, K);
        double rsnew = 0;
        cudaMemcpy(&rsnew, dot_result, sizeof(double), cudaMemcpyDeviceToHost);

        if (sqrt(rsnew) < TOL) break;

        double beta = rsnew / rsold;

        update_p_kernel<<<blocks, threads>>>(p->data, r->data, beta, K);

        rsold = rsnew;
    }

    return x;
}