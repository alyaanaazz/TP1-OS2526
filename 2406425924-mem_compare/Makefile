NPM = 2406425924
CC = gcc

all: static dynamic

static:
	$(CC) -static $(NPM)-mem_compare.c $(NPM)-banner.c -o $(NPM)-mem_static

dynamic:
	$(CC) $(NPM)-mem_compare.c $(NPM)-banner.c -o $(NPM)-mem_dynamic

clean:
	rm -f $(NPM)-mem_static $(NPM)-mem_dynamic *.txt
