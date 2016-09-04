all: network.so

network.so: network.o
	gcc network.o -shared -o network.so

network.o: network.c
	gcc -c -fPIC network.c -o network.o


.PHONY: clean

clean:
	rm *.o *.so