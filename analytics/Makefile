CC=mpicc
CFLAGS=-g -I/net/hu21/pfernand/checkout/phoenix/include
LDFLAGS=-g -L/net/hu21/pfernand/checkout/phoenix/lib -lphoenix -lssl
dummyanalytics: analyze.o
	$(CC) -o $@ $^ $(LDFLAGS)

simpleanalytics: consumer.o
	$(CC) -o $@ $^ $(LDFLAGS)

analyze.o: analyze.c
	$(CC) $(CFLAGS) -c $<

consumer.o: consumer.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -rf analyze.o dummyanalytics consumer.o simpleanalytics

rclean:
	rm -rf stats/*
