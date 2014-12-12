#include <stdio.h>
#include <c_io.h>

#ifdef __cplusplus
extern "C" {
#endif

int write_io_( float *f, int *elements, int *num_proc, int *iid);

void *nv_restart_(char *var, int *id);

int nvchkpt_all_(int *mype);

void* my_alloc_(unsigned int* n, char *s, int *iid);

void* nvread(char *var, int id);

void start_time_(int *processes, int *mype,int *restart);

void pause_time_();

void resume_time_();

void end_time_();

extern void* nvalloc_( size_t size, char *var, int id);


/*Memory protection related methods*/
int enable_protection(void *ptr, size_t size);

int disable_protection(void *ptr) ;

static void
handler(int sig, siginfo_t *si, void *unused);

void install_handler()
/*Memory protection related methods*/

#ifdef __cplusplus
}
#endif
