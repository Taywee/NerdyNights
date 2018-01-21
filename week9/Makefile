FLAGS +=
LDFLAGS += -C../nes.cfg

AS65 ?= ca65
LD65 ?= ld65

ASSEMBLE = $(AS65) $(FLAGS)
LINK = $(LD65) $(LDFLAGS) $(FLAGS)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
dirname := $(basename $(notdir $(patsubst %/,%,$(dir $(mkfile_path)))))

SOURCES = $(wildcard *.asm)
OBJECTS =  $(SOURCES:.asm=.o)

EXECUTABLE = $(dirname).nes

.PHONY: all clean

all: $(EXECUTABLE)
clean:
	-rm -v $(OBJECTS) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS) ../nes.cfg
	$(LINK) -o$@ $<

%.o : %.asm
	$(ASSEMBLE) -o$@ $<
