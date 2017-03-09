CC=mpicc
CFLAGS=-g
LDFLAGS=-g -lphoenix
dummyanalytics: analyze.o
	$(CC) -o $@ $^ $(LDFLAGS)

analyze.o: analyze.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -rf analyze.o dummyanalytics

rclean:
	rm -rf stats/*
