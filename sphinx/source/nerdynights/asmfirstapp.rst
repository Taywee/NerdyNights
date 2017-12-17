*******************
6502 ASM, first app
*******************

.. admonition:: This Week

    Starts getting into more details about the 6502 and intro to assembly
    language. The lessons for asm usage and NES specifics will be done in
    sections together. There are many other 6502 `websites
    <http://www.obelisk.demon.co.uk/6502/>`__ and good books which may help you
    learn better.

Bit
    The smallest unit in computers. It is either a 1 (on) or a 0 (off), like a
    light switch.

Byte
    8 bits together form one byte, a number from 0 to 255. Two bytes put
    together is 16 bits, forming a number from 0 to 65535. Bits in the byte are
    numbered starting from the right at 0.

Instruction
    one command a processor executes. Instructions are run sequentially.

Code Layout
===========

In assembly language there are 5 main parts. Some parts must be in a specific
horizontal position for the assembler to use them correctly.

Directives
----------

Directives are commands you send to the assembler to do things like locating
code in memory. They start with a . and are indented. Some people use tabs, or
4 spaces. This sample directive tells the assembler to put the code starting at
memory location $8000, which is inside the game ROM area::

    .org $8000

We don't use most of these.  For the most part, with cc65, you want to keep that
kind of structure information out of your code.  Your code should describe how
your code functions, and avoid how your code is physically structured as much as
possible. We do that with ``.segment`` directives and a cfg file.  You'll see
programs for older assemblers define all of the structure literally.

For now, this config file is outside the scope of this tutorial.  Just use the
packed ones and trust them, at least to start.

Labels
------

The label is aligned to the far left and has a : at the end. The label is just
something you use to organize your code and make it easier to read. The
assembler translates the label into an address. Sample label::

      .org $8000
    MyFunction:

When the assembler runs, it will do a find/replace to set MyFunction to
$8000. The if you have any code that uses MyFunction like::

      STA MyFunction

It will find/replace to::

      STA $8000

Opcodes
-------

The opcode is the instruction that the processor will run, and is indented like
the directives. In this sample, JMP is the opcode that tells the processor to
jump to the MyFunction label::

      .org $8000
    MyFunction:
      JMP MyFunction

Operands
--------

The operands are additional information for the opcode. Opcodes have between
one and three operands. In this example the #$FF is the operand::

      .org $8000
    MyFunction:
      LDA #$FF
      JMP MyFunction

Comments
--------

Comments are to help you understand in English what the code is doing.  When
you write code and come back later, the comments will save you. You do not need
a comment on every line, but should have enough to explain what is happening.
Comments start with a ; and are completely ignored by the assembler. They can
be put anywhere horizontally, but are usually spaced beyond the long lines::

      .org $8000
    MyFunction:        ; loads FF into accumulator
      LDA #$FF
      JMP MyFunction

This code would just continually run the loop, loading the hex value $FF into
the accumulator each time.

6502 Processor Overview
=======================

The 6502 is an 8 bit processor with a 16 bit address bus. It can access 64KB of
memory without bank switching. In the NES this memory space is split up into
RAM, PPU/Audio/Controller access, and game ROM.

========== ==================================
$0000-0800 Internal RAM, 2KB chip in the NES
$2000-2007 PPU access ports
$4000-4017 Audio and controller access ports
$6000-7FFF Optional WRAM inside the game cart
$8000-FFFF Game cart ROM
========== ==================================

Any of the game cart sections can be bank switched to get access to more
memory, but memory mappers will not be included in this tutorial.

6502 Assembly Overview
======================

The assembly language for 6502 starts with a 3 character code for the
instruction "opcode". There are 56 instructions, 10 of which you will use
frequently. Many instructions will have a value after the opcode, which you can
write in decimal or hex. If that value starts with a # then it means use the
actual number. If the value doesn't have then # then it means use the value at
that address. So LDA #$05 means load the value 5, LDA $0005 means load the
value that is stored at address $0005.

6502 Registers
==============

A register is a place inside the processor that holds a value. The 6502 has
three 8 bit registers and a status register that you will be using.  All your
data processing uses these registers. There are additional registers that are
not covered in this tutorial.

Accumulator
-----------

The Accumulator (A) is the main 8 bit register for loading, storing, comparing,
and doing math on data. Some of the most frequent operations are::

    LDA #$FF  ;load the hex value $FF (decimal 256) into A
    STA $0000 ;store the accumulator into memory location $0000, internal RAM

Index Register X
----------------

The Index Register X (X) is another 8 bit register, usually used for counting
or memory access. In loops you will use this register to keep track of how many
times the loop has gone, while using A to process data. Some frequent
operations are::

    LDX $0000 ;load the value at memory location $0000 into X
    INX       ;increment X   X = X + 1

Index Register Y
----------------

The Index Register Y (Y) works almost the same as X. Some instructions (not
covered here) only work with X and not Y. Some operations are::

    STY $00BA ;store Y into memory location $00BA
    TYA       ;transfer Y into Accumulator

Status Register
---------------

The Status Register holds flags with information about the last
instruction. For example when doing a subtract you can check if the
result was a zero.

6502 Instruction Set
====================

These are just the most common and basic instructions. Most have a few
different options which will be used later. There are also a few more
complicated instructions to be covered later.

Common Load/Store opcodes
-------------------------

::

    LDA #$0A   ; LoaD the value 0A into the accumulator A
               ; the number part of the opcode can be a value or an address
               ; if the value is zero, the zero flag will be set.

    LDX $0000  ; LoaD the value at address $0000 into the index register X
               ; if the value is zero, the zero flag will be set.

    LDY #$FF   ; LoaD the value $FF into the index register Y
               ; if the value is zero, the zero flag will be set.

    STA $2000  ; STore the value from accumulator A into the address $2000
               ; the number part must be an address

    STX $4016  ; STore value in X into $4016
               ; the number part must be an address

    STY $0101  ; STore Y into $0101
               ; the number part must be an address

    TAX        ; Transfer the value from A into X
               ; if the value is zero, the zero flag will be set

    TAY        ; Transfer A into Y
               ; if the value is zero, the zero flag will be set

    TXA        ; Transfer X into A
               ; if the value is zero, the zero flag will be set

    TYA        ; Transfer Y into A
               ; if the value is zero, the zero flag will be set

Common Math opcodes
-------------------

::

    ADC #$01   ; ADd with Carry
               ; A = A + $01 + carry
               ; if the result is zero, the zero flag will be set

    SBC #$80   ; SuBtract with Carry
               ; A = A - $80 - (1 - carry)
               ; if the result is zero, the zero flag will be set

    CLC        ; CLear Carry flag in status register
               ; usually this should be done before ADC

    SEC        ; SEt Carry flag in status register
               ; usually this should be done before SBC

    INC $0100  ; INCrement value at address $0100
               ; if the result is zero, the zero flag will be set

    DEC $0001  ; DECrement $0001
               ; if the result is zero, the zero flag will be set

    INY        ; INcrement Y register
               ; if the result is zero, the zero flag will be set

    INX        ; INcrement X register
               ; if the result is zero, the zero flag will be set

    DEY        ; DEcrement Y
               ; if the result is zero, the zero flag will be set

    DEX        ; DEcrement X
               ; if the result is zero, the zero flag will be set

    ASL A      ; Arithmetic Shift Left
               ; shift all bits one position to the left
               ; this is a multiply by 2
               ; if the result is zero, the zero flag will be set

    LSR $6000  ; Logical Shift Right
               ; shift all bits one position to the right
               ; this is a divide by 2
               ; if the result is zero, the zero flag will be set

Common Comparison opcodes
-------------------------

::

    CMP #$01   ; CoMPare A to the value $01
               ; this actually does a subtract, but does not keep the result
               ; instead you check the status register to check for equal, 
               ; less than, or greater than

    CPX $0050  ; ComPare X to the value at address $0050

    CPY #$FF   ; ComPare Y to the value $FF

Common Control Flow opcodes
---------------------------

::

    JMP $8000  ; JuMP to $8000, continue running code there

    BEQ $FF00  ; Branch if EQual, contnue running code there
               ; first you would do a CMP, which clears or sets the zero flag
               ; then the BEQ will check the zero flag
               ; if zero is set (values were equal) the code jumps to $FF00 and runs there
               ; if zero is clear (values not equal) there is no jump, runs next instruction

    BNE $FF00  ; Branch if Not Equal - opposite above, jump is made when zero flag is clear

NES Code Structure
==================

Getting Started
---------------

This section has a lot of information because it will get everything set up to
run your first NES program. Much of the code can be copy/pasted then ignored
for now. The main goal is to just get NESASM to output something useful.

iNES Header
-----------

The 16 byte iNES header gives the emulator all the information about the game
including mapper, graphics mirroring, and PRG/CHR sizes. You can include all
this inside your asm file at the very beginning.::

      .inesprg 1   ; 1x 16KB bank of PRG code
      .ineschr 1   ; 1x 8KB bank of CHR data
      .inesmap 0   ; mapper 0 = NROM, no bank swapping
      .inesmir 1   ; background mirroring (ignore for now)

Banking
-------

NESASM arranges everything in 8KB code and 8KB graphics banks. To fill the 16KB
PRG space 2 banks are needed. Like most things in computing, the numbering
starts at 0. For each bank you have to tell the assembler where in memory it
will start.::

      .bank 0
      .org $C000
    ;some code here

      .bank 1
      .org $E000
    ; more code here

      .bank 2
      .org $0000
    ; graphics here

Adding Binary Files
-------------------

Additional data files are frequently used for graphics data or level data. The
incbin directive can be used to include that data in your .NES file. This data
will not be used yet, but is needed to make the .NES file size match the iNES
header.::

      .bank 2
      .org $0000
      .incbin "mario.chr"   ;includes 8KB graphics file from SMB1

Vectors
-------

There are three times when the NES processor will interrupt your code and jump
to a new location. These vectors, held in PRG ROM tell the processor where to
go when that happens. Only the first two will be used in this tutorial.

NMI Vector
    this happens once per video frame, when enabled. The PPU tells the
    processor it is starting the VBlank time and is available for graphics
    updates.

RESET Vector
    this happens every time the NES starts up, or the reset button is pressed.

IRQ Vector
    this is triggered from some mapper chips or audio interrupts and will not
    be covered.

These three must always appear in your assembly file the right order.  The .dw
directive is used to define a Data Word (1 word = 2 bytes)::

      .bank 1
      .org $FFFA     ;first of the three vectors starts here
      .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                       ;processor will jump to the label NMI:
      .dw RESET      ;when the processor first turns on or is reset, it will jump
                       ;to the label RESET:
      .dw 0          ;external interrupt IRQ is not used in this tutorial

Reset Code
----------

The reset vector was set to the label RESET, so when the processor starts up it
will start from RESET: Using the .org directive that code is set to a space in
game ROM. A couple modes are set right at the beginning. We are not using IRQs,
so they are turned off. The NES 6502 processor does not have a decimal mode, so
that is also turned off. This section does NOT include everything needed to run
code on the real NES, but will work with the FCEUXD SP emulator. More reset
code will be added later.::

      .bank 0
      .org $C000
    RESET:
      SEI        ; disable IRQs
      CLD        ; disable decimal mode

Completing The Program
----------------------

Your first program will be very exciting, displaying an entire screen of one
color! To do this the first PPU settings need to be written. This is done to
memory address $2001. The 76543210 is the bit number, from 7 to 0. Those 8 bits
form the byte you will write to $2001.

.. _PPUMASK:

+----------------------------------------------------------------+
| :index:`PPUMASK` :index:`($2001) <see: $2001; PPUMASK>`        |
+===+============================================================+
| 7 | Intensify blues (and darken other colors)                  |
+---+------------------------------------------------------------+
| 6 | Intensify greens (and darken other colors)                 |
+---+------------------------------------------------------------+
| 5 | Intensify reds (and darken other colors)                   |
+---+------------------------------------------------------------+
| 4 | Enable sprite rendering                                    |
+---+------------------------------------------------------------+
| 3 | Enable background rendering                                |
+---+------------------------------------------------------------+
| 2 | Disable sprite clipping in leftmost 8 pixels of screen     |
+---+------------------------------------------------------------+
| 1 | Disable background clipping in leftmost 8 pixels of screen |
+---+------------------------------------------------------------+
| 0 | Grayscale (0: normal color; 1: AND all palette entries     |
|   | with 0x30, effectively producing a monochrome display;     |
|   | note that colour emphasis STILL works when this is on!)    |
+---+------------------------------------------------------------+

So if you want to enable the sprites, you set bit 3 to 1. For this program bits
7, 6, 5 will be used to set the screen color::

      LDA %10000000   ;intensify blues
      STA $2001
    Forever:
      JMP Forever     ;infinite loop

Putting It All Together
-----------------------

Download and unzip the `master.zip`_ sample files.  This lesson is in
**background**. All the code above is in the background.asm file. Make sure
that file, mario.chr, and background.bat is in the same folder as
:download:`NESASM3 <files/NESASM3.zip>`, then double click on background.bat.
That will run NESASM3 and should produce background.nes. Run that NES file in
`FCEUXD SP
<http://www.the-interweb.com/serendipity/exit.php?url_id=627_id=90>`__ to see
your background color! Edit background.asm to change the intensity bits 7-5 to
make the background red or green.

You can start the Debug... from the Tools menu in `FCEUXD SP
<http://www.the-interweb.com/serendipity/exit.php?url_id=627&entry_id=90>`__ to
watch your code run. Hit the Step Into button, choose Reset from the NES menu,
then keep hitting Step Into to run one instruction at a time.  On the left is
the memory address, next is the hex opcode that the 6502 is actually running.
This will be between one and three bytes. After that is the code you wrote,
with the comments taken out and labels translated to addresses. The top line is
the instruction that is going to run next. So far there isn't much code, but
the debugger will be very helpful later.

.. _master.zip: https://github.com/Taywee/NerdyNights-sources/archive/master.zip
