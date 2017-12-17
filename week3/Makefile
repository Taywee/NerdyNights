FLAGS +=
LDFLAGS += -C../nes.cfg

AS65 ?= ca65
LD65 ?= ld65

ASSEMBLE = $(AS65) $(FLAGS)
LINK = $(LD65) $(LDFLAGS) $(FLAGS)

SOURCES = week3.asm
OBJECTS =  $(SOURCES:.asm=.o)

EXECUTABLE = week3.nes

.PHONY: all clean

all: $(EXECUTABLE)
clean:
	-rm -v $(OBJECTS) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS) ../nes.cfg
	$(LINK) -o$@ $<

week3.o : week3.asm
	$(ASSEMBLE) -o$@ $<
