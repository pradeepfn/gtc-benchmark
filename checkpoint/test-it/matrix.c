#include <stdio.h>
#include "matrix.h"


void init_matrix(matrix_t A, int value){
	int i,j;
	for(i=0;i<A.m;i++){
		for(j=0;j<A.n;j++){
			A.matrix[i*A.n+j]=value;
		}
	}
} 

void increment_matrix(matrix_t A){
	int i,j;	
	for(i=0;i<A.m;i++){
		for(j=0;j<A.n;j++){
			A.matrix[i*A.n+j]++;
		}
	}

}

void multiply_matrix(matrix_t A, matrix_t B, matrix_t C){
	int i,j,k;
	for(i=0;i<A.m;i++){
		for(k=0;k<B.n;k++){
			C.matrix[i*C.n+k]=0; // init C element
			for(j=0;j<A.n;j++){
				C.matrix[i*C.n+k] += A.matrix[i*A.n+j]*B.matrix[j*B.n+k];
			}
		}
	}


}

void print_matrix(matrix_t A){	
	int i,j;
	for(i=0;i<A.m;i++){
		for(j=0;j<A.n;j++){
			printf("%d  ",A.matrix[i*A.n+j]);
		}
		printf("\n");
	}
}
