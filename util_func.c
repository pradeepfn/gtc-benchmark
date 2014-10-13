#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <openssl/evp.h>
#include <unistd.h>
#include "nv_def.h"
#include "time_delay.h"


#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <strings.h>
#include <time.h>
#include <inttypes.h>
#include <pthread.h>

extern pthread_mutex_t chkpt_mutex;


/* To calculate simulation time */
long simulation_time(struct timeval start, struct timeval end )
{
	long current_time;

	current_time = ((end.tv_sec * 1000000 + end.tv_usec) -
                	(start.tv_sec*1000000 + start.tv_usec));

	return current_time;
}



int gen_rand(int max, int min)
{
	int n=0;
	n=(rand()%((max-min))+min);
  return(n);
}


int rand_word(char *input, int len) {

	int i = 0;
	int max = 122;
	int min = 97;
	
	memset(input, 0, len);
	while ( i < len) {
		input[i] = (char)(gen_rand(max, min));
		i++;
	}
  	input[i] = 0;
	return 0;
}


// Slight variation on the ETH hashing algorithm
//static int magic1 = 1453;
static int MAGIC1 = 1457;
unsigned int gen_id_from_str(char *key) {

	long hash = 0;

	while (*key) {
		hash += ((hash % MAGIC1) + 1) * (unsigned char) *key++;

	}
	return hash % 1699;
}


void convert_base16 (unsigned char num, char *out)
{
    unsigned char mask = 15;
    int i = 0;
    for (i = 1; i >= 0; i--)
    {
        int digit = num >> (i * 4);
        sprintf (out, "%x", digit & mask);
        out++;
    }
    *out = '\0';
}


#ifdef VALIDATE_CHKSM
void sha1_mykeygen(void *key, char *digest, size_t size,
                    int base, size_t input_size) {

    EVP_MD_CTX mdctx;
    const EVP_MD *md;
    unsigned char *md_value = (unsigned char *) malloc(EVP_MAX_MD_SIZE
            * sizeof(unsigned char));
    assert(md_value);
    assert(key);
    assert(digest);		   

    unsigned int md_len, i;
    char digit[10];
    char *tmp;

    if (digest == NULL) {
        perror("Malloc error!");
        exit(1);
    }
    memset(digest, 0, size);
    OpenSSL_add_all_digests();
    md = EVP_get_digestbyname("sha1");
    EVP_MD_CTX_init(&mdctx);
    EVP_DigestInit_ex(&mdctx, md, NULL);
    EVP_DigestUpdate(&mdctx, key, input_size);
    EVP_DigestFinal_ex(&mdctx, md_value, &md_len);
    EVP_MD_CTX_cleanup(&mdctx);

    tmp = digest;
    for (i = 0; i < md_len; i++) {
        convert_base16(md_value[i], digit);
        strcat(tmp, digit);
        tmp = tmp + strlen(digit);
    }
    tmp = '\0';
    digest[size] = '\0';

	//fprintf(stdout,"sha1_mykeygen: %s \n",digest);
}
#endif //VALIDATE_CHECKSUM

int check_modify_access(int perm) {

	return 0;

	if(perm == PROT_NV_RW) {
		return 1;
	}else {
		return 0;
	}

	return 0;
}


int __nsleep(const struct timespec *req, struct timespec *rem)
{
    struct timespec temp_rem;
    if(nanosleep(req,rem)==-1)
        __nsleep(rem,&temp_rem);
    else
        return 1;
}

int msleep(unsigned long nanosec)
{
    struct timespec req={0},rem={0};
    time_t sec=(int)(nanosec/1000000000);
    req.tv_sec=sec;
	req.tv_nsec=nanosec%1000000000;
    __nsleep(&req,&rem);
    return 1;
}
/* write delay shoub be twice as read delay*/
int memcpy_write_delay(void *dest, void *src, size_t len) {
	unsigned long lat_ns, cycles;

	lat_ns = calc_delay_ns(len);
    msleep(lat_ns);
	memcpy(dest,src,len);
	return 0;
}

int memcpy_read_delay(void *dest, void *src, size_t len) {
	unsigned long lat_ns, cycles;

	lat_ns = calc_delay_ns(len);
    msleep(lat_ns);
	memcpy(dest,src,len);
	return 0;
}
