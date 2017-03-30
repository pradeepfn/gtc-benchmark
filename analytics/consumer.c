/* Adapted from mpihello.f by drs */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "phoenix.h"

int main(int argc, char **argv)
{
	char hostname[256];
    unsigned long vsnapshot=0;
	px_init(0);

	while(1){
	printf("simpleconsumer: retrieving snapshot: %ld\n", vsnapshot);
    px_get_snapshot(vsnapshot++);	
    // compute
    sleep(5);
    }
	
    px_finalize();

	return 0;
}
