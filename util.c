#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include "util.h"

//#define NVRAM_BW  450
#define NVRAM_W_BW  600
#define NVRAM_R_BW  2*NVRAM_W_BW

unsigned long calc_delay_ns(size_t datasize,int bandwidth){
        unsigned long delay;
        double data_MB, sec;
        unsigned long nsec;

        data_MB = (double)((double)datasize/(double)pow(10,6));
        sec =(double)((double)data_MB/(double)bandwidth);
        delay = sec * pow(10,9);
        return delay;
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


int memcpy_read(void *dest, void *src, size_t len) {
    unsigned long lat_ns;
    lat_ns = calc_delay_ns(len,NVRAM_R_BW);
    msleep(lat_ns);
    memcpy(dest,src,len);
    return 0;
}

int memcpy_write(void *dest, void *src, size_t len) {
    unsigned long lat_ns;
    lat_ns = calc_delay_ns(len,NVRAM_W_BW);
    msleep(lat_ns);
    memcpy(dest,src,len);
    return 0;
}
