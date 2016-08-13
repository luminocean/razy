all: net.so multiplex.so

net.so: net.o
	gcc net.o -shared -o net.so

net.o: net.c
	gcc -c -fPIC net.c -o net.o

multiplex.so: multiplex.o
	gcc multiplex.o -shared -o multiplex.so

multiplex.o: multiplex.c
	gcc -c -fPIC multiplex.c -o multiplex.o

.PHONY: clean

clean:
	rm *.o *.so