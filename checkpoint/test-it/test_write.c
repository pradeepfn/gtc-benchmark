#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "matrix.h"
#include "mycheckpoint.h"

#define A_ROWS 5
#define B_COLUMNS 10
#define COMMON 3

int main(int argc, char *argv[]){

	//creating matrices	
	matrix_t a;	
	a.m = A_ROWS;
	a.n = COMMON;
	a.matrix = alloc("a",a.m*a.n*sizeof(int),-1,0);

	matrix_t b;
	b.m = COMMON;
	b.n = B_COLUMNS;
	b.matrix = alloc("b",b.m*b.n*sizeof(int),-1,0);
	
	matrix_t c;
	c.m = A_ROWS;
	c.n = B_COLUMNS;
	c.matrix = alloc("c",c.m*c.n*sizeof(int),-1,0);

	//initialize matrices
	init_matrix(a,1);
	init_matrix(b,1);

	print_matrix(a);
	print_matrix(b);
	print_matrix(c);
	 
	int i=0;
	while(1){
		increment_matrix(a);
		increment_matrix(b);
		multiply_matrix(a,b,c);	
		if((a.matrix[0]%1000000)==0){
			printf("checkpointing : %d \n",a.matrix[0]);
			chkpt_all(0);
		}
		i++;
	}	
	exit(0);
}
