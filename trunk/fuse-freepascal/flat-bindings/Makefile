
OBJECTS = FUSE.o Test.o
UNITS = FUSE.ppu Test.ppu

all: Test

FUSE.o FUSE.ppu: FUSE.PP
	fpc -Sa -dFPC FUSE.PP

Test Test.o Test.ppu: Test.PP FUSE.ppu FUSE.o
	fpc -Sa -dFPC Test.PP

clean:
	/bin/rm -f -- Test.o FUSE.ppu FUSE.o

distclean: clean
	/bin/rm -f -- Test
