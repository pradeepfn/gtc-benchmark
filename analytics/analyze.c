/* program hello */
/* Adapted from mpihello.f by drs */

#include <mpi.h>
#include <stdio.h>
#include <unistd.h>

#include "phoenix.h"

int main(int argc, char **argv)
{
	int rank,nproc;
	char hostname[256];
    ulong vsnapshot=0;

	MPI_Init(&argc,&argv);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &nproc);

	px_init(rank,nproc);

	while(true){
    px_get_snapshot(vsnapshot++);	
    // compute
    sleep(1);
    }
	
    px_finalize();
	MPI_Finalize();

	return 0;
}
