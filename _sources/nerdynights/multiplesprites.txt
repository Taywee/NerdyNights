********************************************************
multiple sprites, reading controllers, more instructions
********************************************************

.. admonition:: This Week

    one sprite is boring, so now we add many more!  Also move that sprite
    around using the controller.

Multiple Sprites
================

Last time there was only 1 sprite loaded so we just used a few LDA/STA pairs to
load the sprite data.  This time we will have 4 sprites on screen.  Doing that
many load/stores just takes too much writing and code space.  Instead a loop
will be used to load the data, like was used to load the palette before.  First
the data bytes are set up using the .db directive::

    sprites:
         ;vert tile attr horiz
      .db $80, $32, $00, $80   ;sprite 0
      .db $80, $33, $00, $88   ;sprite 1
      .db $88, $34, $00, $80   ;sprite 2
      .db $88, $35, $00, $88   ;sprite 3

There are 4 bytes per sprite, each on one line.  The bytes are in the correct
order and easily changed.    This is only the starting data, when the program
is running the copy in RAM can be changed to move the sprite around.

Next you need the loop to copy the data into RAM.  This loop also works the
same way as the palette loading, with the X register as the loop counter::

    LoadSprites:
      LDX #$00              ; start at 0
    LoadSpritesLoop:
      LDA sprites, x        ; load data from address (sprites + x)
      STA $0200, x          ; store into RAM address ($0200 + x)
      INX                   ; X = X + 1
      CPX #$10              ; Compare X to hex $10, decimal 16
      BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not
    Equal to zero
                            ; if compare was equal to 16, continue down

If you wanted to add more sprites, you would add lines into the sprite .db
section then increase the CPX compare value.  That will run the loop more
times, copying more bytes.

Once the sprites have been loaded into RAM, you can modify the data there.  

Controller Ports
================

The controllers are accessed through memory port addresses $4016 and $4017. 
First you have to write the value $01 then the value $00 to port $4016.  This
tells the controllers to latch the current button positions.  Then you read
from $4016 for first player or $4017 for second player.  The buttons are sent 
one at a time, in bit 0.  If bit 0 is 0, the button is not pressed.  If bit 0
is 1, the button is pressed.

Button status for each controller is returned in the following order: A, B,
Select, Start, Up, Down, Left, Right::

    LDA #$01
    STA $4016
    LDA #$00
    STA $4016     ; tell both the controllers to latch buttons

    LDA $4016     ; player 1 - A
    LDA $4016     ; player 1 - B
    LDA $4016     ; player 1 - Select
    LDA $4016     ; player 1 - Start
    LDA $4016     ; player 1 - Up
    LDA $4016     ; player 1 - Down
    LDA $4016     ; player 1 - Left
    LDA $4016     ; player 1 - Right

    LDA $4017     ; player 2 - A
    LDA $4017     ; player 2 - B
    LDA $4017     ; player 2 - Select
    LDA $4017     ; player 2 - Start
    LDA $4017     ; player 2 - Up
    LDA $4017     ; player 2 - Down
    LDA $4017     ; player 2 - Left
    LDA $4017     ; player 2 - Right

AND Instruction
===============

Button information is only sent in bit 0, so we want to erase all the other
bits.  This can be done with the AND instruction.  Each of the 8 bits is ANDed
with the bits from another value.  If the bit from both the first AND second
value is 1, then the result is 1.  Otherwise the result is 0.

AND Table
---------

====== ====== ======
byte 1 byte 2 result
====== ====== ======
0      0      0
0      1      0
1      0      0
1      1      1
====== ====== ======

For a full random 8 bit value::

          01011011
    AND   10101101
    --------------
          00001001

We only want bit 0, so that bit is set and the others are cleared::

          01011011    controller data
    AND   00000001    AND value
    --------------
          00000001    only bit 0 is used, everything else erased

So to erase all the other bits when reading controllers, the AND should
come after each read from $4016 or $4017::

    LDA $4016       ; player 1 - A
    AND #%00000001
    
    LDA $4016       ; player 1 - B
    AND #%00000001
    
    LDA $4016       ; player 1 - Select
    AND #%00000001

BEQ instruction
===============

The BNE instruction was used earlier in loops to Branch when Not Equal
to a compared value.  Here BEQ will be used without the compare
instruction to Branch when EQual to zero.  When a button is not pressed,
the value will be zero, so the branch is taken.  That skips over all the
instructions that do something when the button is pressed::

    ReadA: 
      LDA $4016       ; player 1 - A
      AND #%00000001  ; erase everything but bit 0
      BEQ ReadADone   ; branch to ReadADone if button is NOT pressed (0)

                      ; add instructions here to do something when button IS pressed (1)

    ReadADone:        ; handling this button is done

CLC/ADC instructions
====================

For this demo we will use the player 1 controller to move the Mario sprite
around.  To do that we need to be able to add to values.  The ADC instruction
stands for Add with Carry.  Before adding, you have to make sure the carry is
cleared, using CLC.  This sample will load the sprite position into A, clear
the carry, add one to the value, then store back into the sprite position::

    LDA $0203   ; load sprite X (horizontal) position
    CLC         ; make sure the carry flag is clear
    ADC #$01    ; A = A + 1
    STA $0203   ; save sprite X (horizontal) position

SEC/SBC instructions
====================

To move the sprite the other direction, a subtract is needed.  SBC is
Subtract with Carry.  This time the carry has to be set before doing the
subtract::

    LDA $0203   ; load sprite position
    SEC         ; make sure carry flag is set
    SBC #$01    ; A = A - 1
    STA $0203   ; save sprite position

Putting It All Together
=======================

Download and unzip the `controller.zip
<http://www.nespowerpak.com/nesasm/controller.zip>`__ sample files.  All the
code above is in the controller.asm file.  Make sure that file, mario.chr, and
controller.bat is in the same folder as NESASM, then double click on
controller.bat.  That will run NESASM and should produce controller.nes.  Run
that NES file in FCEUXD SP to see small Mario.  Press the A and B buttons on
the player 1 controller to move one sprite of Mario.  The movement will be one
pixel per frame, or 60 pixels per second on NTSC machines.  If Mario isn't
moving, make sure your controls are set up correctly in the Config menu under
Input...  If you hold both buttons together, the value will be added then
subtracted so no movement will happen.

Try editing the ADC and SBC values to make him move faster.  The screen is only
256 pixels across, so too fast and he will just jump around randomly!  Also try
editing the code to move all 4 sprites together.

Finally try changing the code to use the dpad instead of the A and B buttons.
 Left/right should change the X position of the sprites, and up/down should
change the Y position of the sprites.
