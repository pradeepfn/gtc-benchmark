CC=gcc
CFLAGS= -g -Wall -iquote ../
CLFLAGS=


all:
	$(CC) $(CFLAGS) -o test_write test_write.c matrix.c matrix.h ../../checkpt_if.o -L../../ -lnvmchkpt
	$(CC) $(CFLAGS) -o test_read test_read.c matrix.c matrix.h ../../checkpt_if.o -L../../ -lnvmchkpt


clean:
	rm -f *.o
	rm -f test_write
	rm -f test_read

restartclean:
	make -C ../../ restartclean
	rm *.lck0
