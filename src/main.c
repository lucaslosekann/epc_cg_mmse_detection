#include "matrix.h"

int main() {
    Matrix *a = create_matrix(2, 3);

    a->data[0] = 1;
    a->data[1] = 2;
    a->data[2] = 3;
    a->data[3] = 4;
    a->data[4] = 5;
    a->data[5] = 6;

    print_matrix(a);

    free_matrix(a);
    return 0;
}