GCC = gcc
AS_FLAGS = --32 
LD_FLAGS = -m elf_i386
FLAGS = -m32 -g -c


all: bin/telemetry

bin/telemetry: obj/telemetry.o obj/main.o
	$(GCC) -m32 obj/telemetry.o obj/main.o -o bin/telemetry


obj/telemetry.o: src/telemetry.s
	$(GCC) $(FLAGS) src/telemetry.s -o obj/telemetry.o

obj/main.o: src/main.c
	$(GCC) $(FLAGS) src/main.c -o obj/main.o

.PHONY: clean

clean:
	rm -rf obj/*
	rm -rf bin/telemetry
	echo Done!
