FLAGS +=
ASFLAGS +=
LDFLAGS += -C../nes.cfg

AS65 ?= ca65
LD65 ?= ld65

ASSEMBLE = $(AS65) $(ASFLAGS) $(FLAGS)
LINK = $(LD65) $(LDFLAGS) $(FLAGS)

SOURCES = week5.asm
OBJECTS =  $(SOURCES:.asm=.o)

EXECUTABLE = week5.nes

.PHONY: all clean

all: $(EXECUTABLE)
clean:
	-rm -v $(OBJECTS) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS) ../nes.cfg
	$(LINK) -o$@ $<

week5.o : week5.asm
	$(ASSEMBLE) -o$@ $<
