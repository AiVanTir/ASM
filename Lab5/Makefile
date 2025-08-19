CC = gcc
CFLAGS = -Wall -O2
NASM = nasm
NASMFLAGS = -f elf64

OBJS = main.o edge_c.o image_io.o edge_asm.o

all: main

main: $(OBJS)
	$(CC) -o main $(OBJS) -lm

main.o: main.c edge_c.h image_io.h
	$(CC) $(CFLAGS) -c main.c -o main.o

edge_c.o: edge_c.c edge_c.h
	$(CC) $(CFLAGS) -c edge_c.c -o edge_c.o

image_io.o: image_io.c image_io.h stb_image.h stb_image_write.h
	$(CC) $(CFLAGS) -c image_io.c -o image_io.o

edge_asm.o: edge_asm.asm
	$(NASM) $(NASMFLAGS) edge_asm.asm -o edge_asm.o

clean:
	rm -f *.o main

