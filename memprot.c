#include <iostream>
#include <string>
#include <map>
#include <signal.h>
#include <queue>
#include <list>
#include <algorithm>
#include <functional>
#include <pthread.h>
#include <sys/time.h>

#define PAGESIZE 4096

int set_protection(void *addr, size_t len, int flag){

   unsigned long off = 0;
   size_t protect_len =0;

	//align to page boundary
   off = (PAGESIZE- ((unsigned long)addr % PAGESIZE));

	//lets assume offset is 0 for now
	//but requires changes
   addr = addr + off;
   protect_len = len - off;
   off = protect_len % PAGESIZE;      
   protect_len = protect_len -off;

    if (mprotect(addr,protect_len, flag)==-1) {
		fprintf(stdout,"%lu len %u\n", (unsigned long)addr, len);
	    perror("mprotect");
		exit(-1);	
    }
	return 0;
}


size_t remove_chunk_prot(void *addr, int length) {

    unsigned long off = 0;
	//align to page
    off =  (((unsigned long)addr % PAGESIZE));
	if(off){
		 //grant read write protection
		 set_protection(addr-off,length,PROT_READ|PROT_WRITE);
	}	
	return length;
}





