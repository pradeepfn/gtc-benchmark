#define _GNU_SOURCE

#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/queue.h>
#include <unistd.h>
#include <assert.h>
#include <pthread.h>
#include "mycheckpoint.h"


#define FILE_PATH_ONE "/mnt/ramdisk/mmap.file.one"
#define FILE_PATH_TWO "/mnt/ramdisk/mmap.file.two"
//#define FILE_SIZE 600
#define FILE_SIZE 1000000000
#define MICROSEC 1000000
pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
memmap_t m[2];
memmap_t *current;
offset_t offset;
//LIST_HEAD(listhead, entry) head=
//	LIST_HEAD_INITIALIZER(head);
LIST_HEAD(listhead, entry) head;
struct listhead *headp;                 
struct entry {
    void *ptr;
	size_t size;
	int id;
	char var_name[VAR_SIZE];
	int process_id;
	int version;
    LIST_ENTRY(entry) entries;
};

struct timeval t_start;
struct timeval t_end;
size_t tot_rbytes;
unsigned long tot_etime;


unsigned long get_elapsed_time(struct timeval *end, struct timeval *start){
    unsigned long diff = (end->tv_sec - start->tv_sec)*MICROSEC + end->tv_usec - start->tv_usec;
    return diff; 
}

void print_data(checkpoint_t *chkptr){
	printf("variable name : %s\n", chkptr->var_name);
	printf("process id : %d\n", chkptr->process_id);
	//printf("version : %d\n", chkptr->version);
	//printf("is_valid : %d\n", chkptr->is_valid);
	printf("prev_offset : %zd\n", chkptr->prv_offset);
	printf("offset : %zd\n", chkptr->offset);
	printf("data_size : %zd\n\n", chkptr->data_size);
	return;
}


/* Subtract the ‘struct timeval’ values X and Y,
   storing the result in RESULT.
   Return 1 if the difference is negative, otherwise 0. */

int timeval_subtract (struct timeval *result, struct timeval *x, struct timeval *y)
{
  /* Perform the carry for the later subtraction by updating y. */
  if (x->tv_usec < y->tv_usec) {
    int nsec = (y->tv_usec - x->tv_usec) / MICROSEC + 1;
    y->tv_usec -= MICROSEC * nsec;
    y->tv_sec += nsec;
  }
  if (x->tv_usec - y->tv_usec > MICROSEC) {
    int nsec = (x->tv_usec - y->tv_usec) / MICROSEC;
    y->tv_usec += MICROSEC * nsec;
    y->tv_sec -= nsec;
  }

  /* Compute the time remaining to wait.
     tv_usec is certainly positive. */
  result->tv_sec = x->tv_sec - y->tv_sec;
  result->tv_usec = x->tv_usec - y->tv_usec;

  /* Return 1 if result is negative. */
  return x->tv_sec < y->tv_sec;
}



/*
create the initial memory mapped file structure for the first time
and initialize the meta structure.
*/
void init(int process_id){
#ifdef DEBUG
	printf("initializing the structures... %d \n",process_id);
#endif	
	LIST_INIT(&head);
	headp = &head;
	//initializing two mem map files and structures pointing to them
	char file1[256];
	char file2[256];
	snprintf(file1, sizeof file1, "%s%d",FILE_PATH_ONE,process_id);
	snprintf(file2, sizeof file2, "%s%d",FILE_PATH_TWO,process_id);
	mmap_files(&m[0],file1);
	mmap_files(&m[1],file2);
	char lockfile[256];
	snprintf(lockfile, sizeof lockfile, "%s%d","nvm.lck",process_id);
	if(!is_chkpoint_present(process_id,lockfile)){
#ifdef DEBUG
		printf("first run of the process.... no prior checkpointed data!\n");
#endif
		//initialize the head meta structure of the mem map
		copy_head_to_mem(&m[1],1);
		copy_head_to_mem(&m[0],0);
		current = &m[0]; // head meata directly operate on map file memory
	}else{
		// after a restart we find latest map file to operate on
		current = get_latest_mapfile(&m[0],&m[1]);	 
		//printf("current map file is : %d \n", current->head->id);
	}
}

void mmap_files(memmap_t *m, const char *file_name){
    m->fd = open (file_name, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
    lseek (m->fd, FILE_SIZE, SEEK_SET);
    write (m->fd, "", 1); 
    lseek (m->fd, 0, SEEK_SET);
    m->file = mmap (0,FILE_SIZE, PROT_WRITE, MAP_SHARED, m->fd, 0);
	m->head = m->file;
	m->meta =(checkpoint_t *)((headmeta_t *)m->file)+1;
    close (m->fd);
}
//copy the init head metadata portion to memory map
void copy_head_to_mem(memmap_t *m, int fileId){
	headmeta_t head;
	head.id = fileId;
	head.offset = -1;
	gettimeofday(&(head.timestamp),NULL);
	memcpy(m->head,&head,sizeof(headmeta_t));
}

memmap_t *get_latest_mapfile(memmap_t *m1,memmap_t *m2){
	//first check the time stamps of the head values
	headmeta_t *h1 = m1->head;
	headmeta_t *h2 = m2->head;
	struct timeval result;
	//Return 1 if the difference is negative, otherwise 0.
	if(!timeval_subtract(&result, &(h1->timestamp),&(h2->timestamp)) && (h1->offset !=-1)){ 
		return m1;	
	}else if(h2->offset != -1){
		return m2;
	}else{
		printf("Wrong program execution path...");
		assert(0);
	}
}

int myinitialized = 0;
void *alloc(size_t size, char *var_name, int process_id, size_t commit_size){
    pthread_mutex_lock(&mtx);
    //init calls happens once
    if(!myinitialized){
        init(process_id);
        myinitialized = 1;
    }
    struct entry *n = malloc(sizeof(struct entry)); // new node in list
	if(current->head->offset != -1){ // valid checkpoint data present TODO: This fails in multithreaded scenario
#ifdef DEBUG
		printf("retrieving from the checkpointed memory : %s\n", var_name);
#endif
		n->ptr = nvread(var_name,process_id);
	}else{
#ifdef DEBUG
		printf("allocating from the heap space\n");
#endif
		n->ptr = malloc(size); // allocating memory for incoming request
	}
    n->size = size;
	//memcopying the variable names. otherwise
	memcpy(n->var_name,var_name,VAR_SIZE);
#ifdef DEBUG
	printf("variable name : %s\n",var_name);
	printf("variable name stored : %s\n",n->var_name);
#endif
    //n->var_name = var_name;
    n->process_id = process_id;
    n->version = 0;
    LIST_INSERT_HEAD(&head, n, entries);
    pthread_mutex_unlock(&mtx);
    return n->ptr;

}


/* check whether our checkpoint init flag file is present */
int is_chkpoint_present(int process_id, char *filename){
   // struct Checkpoint *chk = (struct Checkpoint *)file_memory;
   //	return chk->is_valid;
   FILE * file = fopen(filename, "r");
   if (file)
    {
        fclose(file);
        return 1;
    }
	file = fopen(filename,"w+");
	fclose(file);
    return 0;
}


extern checkpoint_t *get_latest_version(char *var_name, int process_id){
	checkpoint_t *result;
	memmap_t *other;
	if((result = get_latest_version1(current, var_name, process_id)) == NULL){
		//if result not found in the current mem map file, then switch the files
		// and do search again
#ifdef DEBUG
		printf("Not found in the current memory mapped file. Searching the other...\n");
#endif
		other = (current == &m[0])?&m[1]:&m[0];	
		result = get_latest_version1(other, var_name, process_id);	
	}
	return result;	
}

checkpoint_t *get_latest_version1(memmap_t *mmap, char *var_name, int process_id){
	int temp_offset = mmap->head->offset;
	int str_cmp;
	while(temp_offset >= 0){
	struct timeval t1;
	struct timeval t2;
	gettimeofday(&t1,NULL);
		checkpoint_t *ptr = get_meta(mmap->meta,temp_offset);
	gettimeofday(&t2,NULL);
#ifdef DEBUG
		printf("comparing values  process ids (%d, %d) - (%s, %s)\n",ptr->process_id, process_id,ptr->var_name,var_name);
#endif
		if((ptr->process_id == process_id) && (str_cmp=strncmp(ptr->var_name,var_name,10))==0){ // last char is null terminator
			return ptr;
		}
		temp_offset = ptr->prv_offset;
	}
	return NULL;//to-do, handle exception cases
}
size_t tot_chkpt_size;
int is_remaining_space_enough(int process_id){
	size_t tot_size=0;
	struct entry *np;
	for (np = head.lh_first; np != NULL; np = np->entries.le_next){
		if(np->process_id == process_id){ 
			tot_size+=(sizeof(checkpoint_t)+np->size);	
		}
	}	
    tot_chkpt_size = tot_size;	
	if(tot_size > (FILE_SIZE - sizeof(headmeta_t))){
#ifdef DEBUG
		printf("allocated buffer is not sufficient for program exec\n");
#endif
		assert(0);
	}
	size_t remain_size = FILE_SIZE - (sizeof(headmeta_t) + current->head->offset+1); //adding 1 since offset can be -1
	return (remain_size > tot_size); 
}


 void chkpt_all(int process_id){
	pthread_mutex_lock(&mtx);
	struct timeval t1;
	struct timeval t2;
	gettimeofday(&t1,NULL);
#ifdef DEBUG
	printf("checkpointing data of process : %d \n",process_id);
#endif
	if(!is_remaining_space_enough(process_id)){
#ifdef DEBUG
		printf("remaining space is not enough. Switching to other file....\n");
		//swap the persistant memory if not enough space
		printf("current map file is : %d \n", current->head->id);
#endif
		current = (current == &m[0])?&m[1]:&m[0];	
		current->head->offset = -1; // invalidate the data
		gettimeofday(&(current->head->timestamp),NULL); // setting the timestamp
#ifdef DEBUG
		printf("current map file after switch is : %d \n", current->head->id);
#endif
	}
	struct entry *np;
	for (np = head.lh_first; np != NULL; np = np->entries.le_next){
		if(np->process_id == process_id){ 
			checkpoint(np->var_name, np->process_id, np->version,	np->size,np->ptr);
		}
	}	
	gettimeofday(&t2,NULL);
	//printf("time checkpoint: (%zd,%zd) \n",tot_chkpt_size, get_elapsed_time(&t2,&t1));
	pthread_mutex_unlock(&mtx);
	return;
}

/*
	try checkpointing to current mem map file if space is not enough
	switch to next mem map file and do checkpointing.
*/
extern void checkpoint(char *var_name, int process_id, int version, size_t size, void *data){
	checkpoint2(current->meta,var_name, process_id, version,size,data);
	return;	
}

void checkpoint2(void *base_addr, char *var_name, int process_id, int version, size_t size, void *data){
	checkpoint_t chkpt;
	void *start_addr;
	strncpy(chkpt.var_name,var_name,VAR_SIZE-1);
	chkpt.var_name[VAR_SIZE-1] = '\0'; // null terminating
#ifdef DEBUG
	printf("checkpoint var name : %s\n",chkpt.var_name);
#endif
	chkpt.process_id = process_id;
	chkpt.version = version;
	chkpt.data_size = size;
	if(current->head->offset != -1 ){
		checkpoint_t *last_meta = get_meta(base_addr, current->head->offset);
		start_addr = get_start_addr(base_addr, last_meta);
		chkpt.prv_offset = current->head->offset;
		chkpt.offset = last_meta->offset + sizeof(checkpoint_t)+last_meta->data_size;
	}else{
		start_addr = current->meta;
		chkpt.prv_offset = -1;
		chkpt.offset = 0;
	}
	//print_data(&chkpt);
	checkpoint1(start_addr, &chkpt,data);
	return;
}


void checkpoint1(void *start_addr, checkpoint_t *chkpt, void *data){ 
	//copy the metadata 
	memcpy(start_addr,chkpt,sizeof(checkpoint_t));
	//copy the actual value after metadata.
	void *data_offset = ((char *)start_addr)+sizeof(checkpoint_t); 
	memcpy(data_offset,data,chkpt->data_size);
	//directly operating on the mapped memory
	current->head->offset = chkpt->offset;
	return;
}        

void *get_start_addr(void *base_addr,checkpoint_t *last_meta){
	size_t tot_offset = last_meta->offset + sizeof(checkpoint_t) + last_meta->data_size;
	char *next_start_addr = (char *)base_addr+tot_offset;
	return (void *)next_start_addr;
}

checkpoint_t *get_meta(void *base_addr,size_t offset){
	checkpoint_t *ptr = (checkpoint_t *)(((char *)base_addr) + offset);
	return ptr; 
}

void *get_data_addr(void *base_addr, checkpoint_t *chkptr){
	char *temp = ((char *)base_addr) + chkptr->offset + sizeof(checkpoint_t);
	return (void *)temp;
}

void *get_addr(void *base_addr, size_t offset){
	char *temp = ((char *)base_addr)+offset;
	return temp;
}

int get_new_offset(offset_t offset, size_t data_size){
	int temp = offset + sizeof(checkpoint_t) + data_size; 
	return temp; 
}

void* alloc_( unsigned int size, char *var, int id, int commit_size)
{
		//printf("allocating space : %d \n", size);
		return malloc(size);
}

// allocates n bytes using the 
void* my_alloc_(unsigned int* n, char *s, int *iid, int *cmtsize) {
	return alloc(*n, s, *iid, *cmtsize); 
}
 
void my_free_(char* arr) {
  free(arr);
}
  

int nvchkpt_all_(int *mype) {
	//printf("Checkpointing. Calling newly implemented function\n");
	chkpt_all(*mype);
	return 1;
}

void *nvread(char *var, int id){
	//struct timeval t1;
	//struct timeval t2;
	//gettimeofday(&t1,NULL);
    void *buffer=NULL;
    void *data_addr = NULL;
    checkpoint_t *checkpoint = get_latest_version(var,id);
	if(checkpoint == NULL){ // data not found
		printf("Error data not found");
		assert(0);
		return NULL;
	}
#ifdef DEBUG
	print_data(checkpoint);
#endif
    data_addr = get_data_addr(current->meta,checkpoint);
    int i;
    buffer = malloc(checkpoint->data_size);
    //copying the memory back from checkpointed block   
    memcpy(buffer,data_addr,checkpoint->data_size);
	//gettimeofday(&t2,NULL);
	//printf("nvread (bytes : time): (%zd,%zd) \n",checkpoint->data_size, get_elapsed_time(&t2,&t1));
	tot_rbytes += checkpoint->data_size;
    return buffer;
}

FILE *fp;
int irun;
void start_time_(int *processes, int *mype, int *mpsi, int *restart){
	irun=*restart;
	if(irun == 1){
		char file_name[50];
		snprintf(file_name,sizeof(file_name),"stats/nvram_n%d_p%d_mpsi%d.log",*processes,*mype,*mpsi);
		fp=fopen(file_name,"w");
		fprintf(fp,"bytes,micro_sec\n");
	}
	gettimeofday(&t_start,NULL);
	tot_rbytes =0;
	tot_etime=0;
}

void pause_time_(){
	gettimeofday(&t_end,NULL);
	tot_etime+=get_elapsed_time(&t_end,&t_start);

}

void resume_time_(){
	gettimeofday(&t_start,NULL);
}

void end_time_(){
	gettimeofday(&t_end,NULL);
	tot_etime+=get_elapsed_time(&t_end,&t_start);
	if(irun == 1){//write upon valid data reads
		fprintf(fp,"%lu,%lu\n",tot_rbytes,tot_etime);
		fclose(fp);
	}
	printf("batch read (bytes : time ): ( %zd :  %zd ) \n",tot_rbytes, tot_etime);
}
