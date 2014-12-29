
typedef struct _matrix_t{
	int *matrix;
	int m;
	int n;
}matrix_t;


void init_matrix(matrix_t A, int value);
void increment_matrix(matrix_t A);
void multiply_matrix(matrix_t A, matrix_t B, matrix_t C);
void print_matrix(matrix_t A);




