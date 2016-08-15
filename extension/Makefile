all: network.so multiplex.so

network.so: network.o
	gcc network.o -shared -o network.so

network.o: network.c
	gcc -c -fPIC network.c -o network.o

multiplex.so: multiplex.o
	gcc multiplex.o -shared -o multiplex.so

multiplex.o: multiplex.c
	gcc -c -fPIC multiplex.c -o multiplex.o

.PHONY: clean

clean:
	rm *.o *.so