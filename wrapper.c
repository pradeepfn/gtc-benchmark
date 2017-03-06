#include <assert.h>
#include "phoenix.h"


int px_init_(int *proc_id){
    return px_init(*proc_id);
}

void *alloc(unsigned int *n, char *s, int *iid, int *cmtsize) {
    px_obj temp;
    px_create(s, *n,&temp);
	assert(*n == temp.size);
	return temp.data;
}

void px_free_(void* ptr) {
    px_delete(ptr);
}

void px_snapshot_(){
    px_snapshot();
}

int px_finalize_(){
    return px_finalize();
}

