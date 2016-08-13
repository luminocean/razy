# multiplex: clean
#	gcc multiplex.c -o multiplex

# .PHONY: clean
#clean:
#	rm multiplex

multiplex.so: multiplex.o
	gcc multiplex.o -shared -o multiplex.so

multiplex.o: multiplex.c
	gcc -c -fPIC multiplex.c -o multiplex.o

.PHONY: clean
clean:
	rm *.o *.so