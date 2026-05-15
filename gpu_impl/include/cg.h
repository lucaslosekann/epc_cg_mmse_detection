#ifndef CG_H
#define CG_H
#include "matrix.h"
#include "vector.h"
#define TOL 1e-4

Vector *compute(const Matrix *H, const Vector *y, const double sigma_sq, const int iterations);

#endif // CG_H