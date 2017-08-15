CFLAGS= -f elf32
LFLAGS= -m elf_i386

all: crypter

crypter: crypter.o
	ld $(LFLAGS) crypter.o -o crypter

crypter.o: asm_crypter.asm
	nasm $(CFLAGS) asm_crypter.asm -o crypter.o

clean: 
	rm -f crypter.o crypter

.INTERMEDIATE: crypter.o
