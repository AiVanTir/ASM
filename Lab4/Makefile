
LDFLAGS = -static -z noexecstack
LIBPATH = -L /lib/gcc/x86_64-linux-gnu/13/ -L /lib
LIBS = -lc -lgcc -lgcc_eh -lm

OBJPATH = /usr/lib/x86_64-linux-gnu
PREOBJ = $(OBJPATH)/crt1.o $(OBJPATH)/crti.o
POSTOBJ = $(OBJPATH)/crtn.o

all:
	nasm -g -f elf64 lab.s -o lab.o
	ld $(LDFLAGS) $(LIBPATH) $(PREOBJ) lab.o $(POSTOBJ) $(LIBS) -o lab
