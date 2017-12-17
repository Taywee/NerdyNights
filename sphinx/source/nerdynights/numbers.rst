*******************
Numbers, Bin to Dec
*******************

.. admonition:: This Week

    NES uses binary and hex, but your gamers want to read in decimal? Here are two
    solutions for displaying scores and other numbers in a readable way.

BCD Mode
========

The 6502 processor has a mode called BCD, or Binary Coded Decimal, where the
adc/sbc instructions properly handle decimal numbers instead of binary numbers.
The NES is not a full 6502 processor and does not include this mode. Be careful
when you are searching for code to not copy any that uses that mode, or you
will get incorrect results. If the code is doing a SED instruction, it is
enabling the decimal mode and you should not use it. Instead you get to do all
the decimal handling yourself!

Storing Digits
==============

The first method uses more code, but may be easier to understand. Say your
score is a 5 digit number. You will make 5 variables, one for each digit. Those
variables will only count from 0 to 9 so you need to write code to handle
addition and subtraction. Super Mario uses this method.  It's lowest digit is
always 0, so that isn't actually stored in a variable. Instead it is just a
permanent part of the background.

We will start with just incrementing a 3 digit number to see how its done::

    IncOnes:
      LDA onesDigit     ; load the lowest digit of the number
      CLC 
      ADC #$01          ; add one
      STA onesDigit
      CMP #$0A          ; check if it overflowed, now equals 10
      BNE IncDone       ; if there was no overflow, all done
    IncTens:
      LDA #$00
      STA onesDigit     ; wrap digit to 0
      LDA tensDigit     ; load the next digit
      CLC 
      ADC #$01          ; add one, the carry from previous digit
      STA tensDigit
      CMP #$0A          ; check if it overflowed, now equals 10
      BNE IncDone       ; if there was no overflow, all done
    IncHundreds:
      LDA #$00
      STA tensDigit     ; wrap digit to 0
      LDA hundredsDigit ; load the next digit
      CLC 
      ADC #$01          ; add one, the carry from previous digit
      STA hundredsDigit
    IncDone:

When the subroutine starts, the ones digit is incremented. Then it is checked
if it equals $0A which is decimal 10. That number doesn't fit in just one
digit, so the ones digit is set to 0 and the tens digit is incremented. The
tens digit is then checked in the same way, and the chain continues for as many
digits as you want.

The same process is used for decrementing, except you check for underflow
(digit=$FF) and wrap the digit to $09.

Adding two numbers is the same idea, except other than checking if each digit
equals $0A you need to check if the digit is $0A or above. So instead of BEQ
the opcode will be BCC::

    AddOnes:
      LDA onesDigit      ; load the lowest digit of the number
      CLC 
      ADC onesAdd        ; add new number, no carry
      STA onesDigit
      CMP #$0A           ; check if digit went above 9. If accumulator >= $0A, carry is set
      BCC AddTens        ; if carry is clear, all done with ones digit
                         ; carry was set, so we need to handle wrapping
      LDA onesDigit
      SEC
      SBC #$0A           ; subtract off what doesnt fit in 1 digit
      STA onesDigit      ; then store the rest
      INC tensDigit      ; increment the tens digit
    AddTens:
      LDA tensDigit      ; load the next digit
      CLC
      ADC tensAdd        ; add new number
      STA tensDigit
      CMP #$0A           ; check if digit went above 9
      BCC AddHundreds    ; no carry, digit done
      LDA tensDigit
      SEC
      SBC #$0A           ; subtract off what doesnt fit in 1 digit
      STA tensDigit      ; then store the rest
      INC hundredsDigit  ; increment the hundreds digit
    AddHundreds:
      LDA hundredsDigit  ; load the next digit
      CLC
      ADC hundredsAdd    ; add new number
      STA hundredsDigit
    AddDone:

When that code is all done, the ones/tens/hundreds digits will hold the new
value. With both code samples there is no check at the end of the hundreds
digit. That means when the full number is 999 and you add one more, the result
will be wrong! In your code you can either wrap around all the digits to 0, or
set all the digits to 999 again for a maximum value. Of course if your players
are hitting the max they likely want more digits!

Binary to Decimal Conversion
============================

The second method of handling number displays uses less code, but could use
much more CPU time. The idea is to keep you numbers in plain binary form (8 or
16 bit variables) for the math, then convert them to decimal for displaying
only. An 8 bit binary value will give you 3 decimal digits, and a 16 bit binary
will give 5 decimal digits.  This first example is coded to be understandable,
not fast or small.  Each step compares the binary value to a significant
decimal value (100 and then 10). If the binary is larger, that value is
subtracted from the binary and the final decimal digit is incremented. So for a
text example::

    initial binary: 124
    initial decimal: 000

::

    1: compare to 100
    2: 124 greater than 100, so subtract 100 and increment the decimal hundreds digit
    3: repeat hundreds again

::

    current binary: 024
    current decimal: 100

::

    1: compare to 100
    2: 024 less than 100, so all done with hundreds digit

::

    current binary: 024
    current decimal: 100

::

    1: compare to 10
    2: 024 greater than 10, so subtract 10 and increment the decimal tens digit
    3 repeat tens again

::

    current binary: 014
    current decimal: 110

::

    1: compare to 10
    2: 014 greater than 10, so subtract 10 and increment the decimal tens digit
    3 repeat tens again

::

    current binary: 004
    current decimal: 120

::

    etc for ones digit

You can see this will transfer the binary to decimal one digit at a time. For
numbers with large digits (like 249) this will take longer than numbers with
small digits (like 112). Here is the code::

    HundredsLoop:
      LDA binary
      CMP #100             ; compare binary to 100
      BCC TensLoop         ; if binary < 100, all done with hundreds digit
      LDA binary
      SEC
      SBC #100
      STA binary           ; subtract 100, store whats left
      INC hundredsDigit    ; increment the digital result
      JMP HundredsLoop     ; run the hundreds loop again

::

    TensLoop:
      LDA binary
      CMP #10              ; compare binary to 10
      BCC OnesLoop         ; if binary < 10, all done with hundreds digit
      LDA binary
      SEC
      SBC #10
      STA binary           ; subtract 10, store whats left
      INC tensDigit        ; increment the digital result
      JMP TensLoop         ; run the tens loop again

::

    OnesLoop:
      LDA binary
      STA onesDigit        ; result is already under 10, can copy directly to result

This code can be expanded to 16 bit numbers, but the compares become harder.
Instead a more complex series of loops and shifts with a table is used. This
code does shifting of the binary value into the carry bit to tell when to add
numbers to the final decimal result. I did not write this code, it came from a
post by Tokumaru at `Parodius`_.  There are many more examples of different
conversion styles at that forum thread.

Notice there are no branches other than the loop running 16 times (one
for each binary input bit), so the conversion always takes the same
number of cycles:

tempBinary
    16 bits input binary value
decimalResult
    5 bytes for the decimal result

::

    BinaryToDecimal:
       lda #$00 
       sta decimalResult+0
       sta decimalResult+1
       sta decimalResult+2
       sta decimalResult+3
       sta decimalResult+4
       ldx #$10 
    BitLoop: 
       asl tempBinary+0 
       rol tempBinary+1
       ldy decimalResult+0
       lda BinTable, y 
       rol a
       sta decimalResult+0
       ldy decimalResult+1
       lda BinTable, y 
       rol a
       sta decimalResult+1
       ldy decimalResult+2
       lda BinTable, y 
       rol a
       sta decimalResult+2
       ldy decimalResult+3
       lda BinTable, y 
       rol a
       sta decimalResult+3
       rol decimalResult+4
       dex 
       bne BitLoop 
       rts 
    BinTable:
       .db $00, $01, $02, $03, $04, $80, $81, $82, $83, $84

Displaying Numbers
==================

Once you have your numbers in decimal format you need to display them on the
screen. With the code above all the results have 00000 = $00 $00 $00 $00 $00.
If your background tiles for digits start at tile 0 then that will work fine.
However if you are using ASCII you will need to add an offset to each digit.
The ASCII code for the digit 0 is $30, so you just add $30 to each digit before
writing it to the background. If your code uses the first method of
compare/wrapping digits, then you could compare to $3A and wrap to $30 to
automatically handle this. You would just need to make sure you set each digit
to $30 instead of $00 when clearing the number to 00000. You have control over
where background tiles are located, so the offset for the digit tiles can be
whatever you choose.

Putting It All Together
=======================

Download and unzip the `master.zip`_ sample files.  This lesson is in
**pong2**.  The playing game state and ball movement code is in the pong2.asm
file. Make sure that file, mario.chr, and pong2.bat is in the same folder as
NESASM3, then double click on pong1.bat. That will run NESASM3 and should
produce pong2.nes.  Run that NES file in FCEUXD SP to see the score! Right now
the score just increments every time the ball bounces off a side wall.

Try making two scoring variables and drawing them both. You can also use the
other binary to decimal converters to add more than 1 to the score each time.
In the DrawScore you can also check the score digits and not draw any leading
zeros. Instead replace them with spaces when you are drawing to the background.

.. _Parodius: http://nesdev.parodius.com/bbs/viewtopic.php?p=10824&sid=55359b42282d1e02b91bebcf1caf56ef#10824
.. _master.zip: https://github.com/Taywee/NerdyNights-sources/archive/master.zip
