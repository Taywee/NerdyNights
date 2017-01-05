***********************************
16 bit math, pointers, nested loops
***********************************

.. admonition:: This Week

    The NES is an 8 bit machine, but sometimes you need more!  Learn to handle
    16+ bit numbers, and use them for bigger loops.

16 Bit Math
===========

Doing 16 bit addition and subtraction is fairly simple because of the carry
flag that we had previously been clearing. First the normal add is done using
the clc/adc pair. This add is for the lower 8 bits of the 16 bit number. For
the upper 8 bits the adc instruction is used again, but without the clc. You
want to keep the carry from the first add, in case it overflowed. To only add
in the carry the second adc value is just 0.

Here are some examples in decimal. One digit column is added at a time.  The
carry (1) is added to the next column as needed.

::

      0 3
    + 0 4
      0 7  (no carry needed, top digit = 0)

::

      0 4
    + 0 8
      1 2  (carry only, top digit = 1)

::

      2 2
    + 1 9
      4 1  (carry plus 2 plus 1, top digit = 4)

And the code to do it on the NES, adding 1 to a 16 bit number::

      LDA lowbyte      ; load low 8 bits of 16 bit value
      CLC              ; clear carry
      ADC #$01         ; add 1
      STA lowbyte      ; done with low bits, save back
      LDA highbyte     ; load upper 8 bits
      ADC #$00         ; add 0 and carry from previous add
      STA highbyte     ; save back

The same process of adding 0 without clearing the carry can be continued to do
24 bit, 32 bit, or higher numbers. It is also the same process to do 16 bit
subtraction::

      LDA lowbyte      ; load low 8 bits of 16 bit value
      SEC              ; set carry
      SBC #$01         ; subtract 1
      STA lowbyte      ; done with low bits, save back
      LDA highbyte     ; load upper 8 bits
      SBC #$00         ; subtract 0 and carry from previous sub
      STA highbyte     ; save back

Pointers and Indirect Indexed Mode
==================================

Previously when loading background tiles the x register was used as an 8 bit
offset. Now that we can handle 16 bit numbers a different addressing mode can
be used. The 16 bit address is saved into two 8 bit variables, which are then
used as a **pointer** which points to the background data we want. The LDA
instruction then uses the **Indirect Indexed** addressing mode. This takes the
16 bit variable inside the brackets and uses it as an address. For the address
to be correct, the low byte must be first and the high byte must come
immediately after.  Then the value in the Y register is added to the address.
This forms the final address to load from. Both variables must also be in the
first 256 bytes of RAM, called **Zero Page**, and the X register cannot be used
with this addressing mode::

      .rsset $0000       ; put pointers in zero page
    pointerLo  .rs 1   ; pointer variables are declared in RAM
    pointerHi  .rs 1   ; low byte first, high byte immediately after

::

      LDA #$D0
      STA pointerHi
      LDA #$12
      STA pointerLo       ; pointer now says $D012

::

      LDY #$00            ; no offset from Y
      LDA [pointerLo], y  ; load data from the address pointed to by the 16 bit pointer variable plus the value in the Y register

That last line is the same as::

    LDA $D012, y

Because we kept Y = 0, that is the same as::

    LDA $D012

Copy Loops
==========
Now using your 16 bit math the pointer address can be incremented.  Instead of
being limited to 256 background tiles like when using the x offset, the whole
background can be copied in one loop. First the address of the background data
is put into the pointer variable. The high and low bytes of the address are
each copied individually. Then the number of tiles to copy is put into the loop
counter, which will count down to 0. Each time through the loop one byte will
be copied, the 16 bit pointer address will be incremented, and the 16 bit loop
counter will be decremented. The Y offset is always kept at 0, because the
pointer always points to the correct byte. When the loop counter reaches 0
everything is done::

      LDA #LOW(background)
      STA pointerLo       ; put the low byte of the address of background into pointer
      LDA #HIGH(background)
      STA pointerHi       ; put the high byte of the address into pointer

::

      LDA #$00
      sta counterLo       ; put the loop counter into 16 bit variable
      LDA #$04
      sta counterHi       ; count = $0400 = 1KB, the whole screen at once including attributes

::

      
      LDY #$00            ; put y to 0 and don't change it
    LoadBackgroundLoop:
      LDA [pointerLo], y
      STA $2007           ; copy one background byte

::

      LDA pointerLo
      CLC
      ADC #$01
      STA pointerLo
      LDA pointerHi
      ADC #$00
      STA pointerHi       ; increment the pointer to the next byte

::

      
      LDA counterLo
      SEC
      SBC #$01
      STA counterLo
      LDA counterHi
      SBC #$00
      STA counterHi       ; decrement the loop counter

::

      
      LDA counterLo
      CMP #$00
      BNE LoadBackgroundLoop
      LDA counterHi
      CMP #$00
      BNE LoadBackgroundLoop  ; if the loop counter isn't 0000, keep copying
     

That is a lot of code to copy just one byte!

Nested Loops
============

To avoid using so much code, we can use both the X and Y registers as loop
counters. By putting one loop inside another loop we create a "nested loop".
First the inside loop counts all the way up. Then the outside loop counts up
once, and the inside loop counts all the way again. Normally using only X or Y
would only give a maximum of 256 times through a loop like we have previously
done. With nested loops using both X and Y the maximum is the inside counter
multiplied by the outside counter, or 256\*256 = 65536::

      LDX #$00
      LDY #$00
    OutsideLoop:
      
    InsideLoop:
      ;
      ; this section runs 256 x 256 times
      ;
      
      INY                 ; inside loop counter
      CPY #$00
      BNE InsideLoop      ; run the inside loop 256 times before continuing down
      
      INX
      CPX #$00
      BNE OutsideLoop     ; run the outside loop 256 times before continuing down


First the Inside Loop runs and Y will count from 0 to 256. When that finishes X
will count 0 to 1, and branch back to the beginning of the loops. Then the
Inside Loop runs again, Y 0 -> 256. X now goes 1 -> 2 and the process
continues. Everything ends when both X and Y have each counted to 256.

When we are using nested loops to copy entire backgrounds we want 256 x 4 =
1KB. The Y code from above can be unchanged, but the X code is changed to CPX
#$04.

Because we are changing the Y register our previous pointer copying code also
needs to be modified. Instead of incrementing the pointer every time, the
incrementing Y register is doing the same thing. The low byte of the pointer
will be kept at 0. This means your background data needs to be aligned to where
the low byte of the address is $00. However the high byte of the pointer still
needs to change. By always making the inside loop count 256 times, that will
end at the same time that the high byte needs to change. This time 16 bit math
isn't needed because only the high byte is incremented.

No loop counter is used because X and Y are used instead. If you cannot align
your data so the low byte of the address is $00, you will have to use the
CopyLoop above::

      LDA #$00
      STA pointerLo       ; put the low byte of the address of background into pointer
      LDA #HIGH(background)
      STA pointerHi       ; put the high byte of the address into pointer
      
      LDX #$00            ; start at pointer + 0
      LDY #$00
    OutsideLoop:
      
    InsideLoop:
      LDA [pointerLo], y  ; copy one background byte from address in pointer plus Y
      STA $2007           ; this runs 256 * 4 times
      
      INY                 ; inside loop counter
      CPY #$00
      BNE InsideLoop      ; run the inside loop 256 times before continuing down
      
      INC pointerHi       ; low byte went 0 to 256, so high byte needs to be changed now
      
      INX
      CPX #$04
      BNE OutsideLoop     ; run the outside loop 256 times before continuing down

Putting It All Together
=======================

Download and unzip the `master.zip`_ sample files.  This lesson is in
**background3**. All the code is in the background.asm file. Make sure that file,
mario.chr, and background.bat is in the same folder as NESASM, then double
click on background.bat. That will run NESASM and should produce
background3.nes. Run that NES file in FCEUXD SP to see the full background.

The new nested loop is used to copy a whole background to the screen instead of
only 128 bytes.  The background is aligned using the .org directive so the low
address byte is $00.  The attributes are also placed directly after the
background data so it is are copied at the same time.

Your task is to separate out the code that sets the pointer variables from the
code that copies the loop. That way you can have multiple backgrounds that use
different pointer loading code, but the same copy code.

If you are using a different assembler, the Indirect Indexed mode may use ()
instead of []. The LOW() and HIGH() syntax may also be different.

.. _master.zip: https://github.com/Taywee/NerdyNights-sources/archive/master.zip
