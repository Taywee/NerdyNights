***************************************
subroutines, game layout, starting Pong
***************************************

.. admonition:: This Week

    Most of this lesson is about how to organize and structure your game.
    Subroutines and game states help arrange the code for easier reading and
    reuse of code.  

Variables
=========

As covered in week 1, variables are data stored in RAM that you can change any
time.  The sprite data in RAM is all variables.  You will need more variables
for keeping track of things like the score in the game.  To do that you first
need to tell NESASM where in RAM to put the variable.  This is done using the
.rsset and .rs directives.  First .rsset is used to set the starting address of
the variable.  Then .rs is used to reserve space.  Usually just 1 byte is
reserved, but you can have as much as you want.  Each time you do a .rs the
address gets incremented so you don't need to do .rsset again::

    .rsset $0000    ;put variables starting at 0
    score1   .rs 1  ;put score for player 1 at $0000
    score2   .rs 1  ;put score for player 2 at $0001
    buttons1 .rs 1  ;put controller data for player 1 at $0002
    buttons2 .rs 1  ;put controller data for player 2 at $0003

Once you set the address for the variable, you do not need to know the
address anymore.  You can just reference it using the variable name you
created.  You can insert more variables above the current ones and the
assembler will automatically recalculate the addresses.

Constants
=========

Constants are numbers that you do not change.  They are just used to make your
code easier to read.  In Pong an example of a constant would be the position of
the outer walls.  You will need to compare the ball position to the walls to
make the ball bounce, but the walls do not change so they are good constants. 
Doing a compare to LEFTWALL is easier to read and understand than a comparison
to $F6.

To declare constants you use the = sign::

    RIGHTWALL      = $02 ; when ball reaches one of these, do something
    TOPWALL        = $20
    BOTTOMWALL     = $D8
    LEFTWALL       = $F6

The assembler will then do a find/replace when building your code.

Subroutines
===========

As your program gets larger, you will want subroutines for organization and to
reuse code.  Instead of progressing linearly down your code, a subroutine is a
block of code located somewhere else that you jump to, then return from.  The
subroutine can be called at any time, and used as many times as you want.  Here
is what some code looks like without subroutines::

    RESET:
      SEI          ; disable IRQs
      CLD          ; disable decimal mode

    vblankwait1:       ; First wait for vblank to make sure PPU is ready
      BIT $2002
      BPL vblankwait1

    clrmem:
      LDA #$FE
      STA $0200, x
      INX
      BNE clrmem

    vblankwait2:      ; Second wait for vblank, PPU is ready after this
      BIT $2002
      BPL vblankwait2

Notice that the vblankwait is done twice, so it is a good choice to turn
into a subroutine.  First the vblankwait code is moved outside the
normal linear flow::

    vblankwait:      ; wait for vblank
      BIT $2002
      BPL vblankwait

    RESET:
      SEI          ; disable IRQs
      CLD          ; disable decimal mode

    clrmem:
      LDA #$FE
      STA $0200, x
      INX
      BNE clrmem

Then that code needs to be called, so the JSR (Jump to SubRoutine)
instruction is where the vblankwait code used to be::

    RESET:
      SEI          ; disable IRQs
      CLD          ; disable decimal mode

      JSR vblankwait  ;;jump to vblank wait #1

    clrmem:
      LDA #$FE
      STA $0200, x
      INX
      BNE clrmem

      JSR vblankwait  ;; jump to vblank wait again

And then when the subroutine has finished, it needs to return back to
the spot it was called from.  This is done with the RTS (ReTurn from
Subroutine) instruction.  The RTS will jump back to the next instruction
after the JSR::

         vblankwait:      ; wait for vblank  <--------
           BIT $2002                                  \
           BPL vblankwait                              |
     ----- RTS                                         |
    /                                                  |
    |    RESET:                                        |
    |      SEI          ; disable IRQs                 |
    |      CLD          ; disable decimal mode         |
    |                                                  |
    |      JSR vblankwait  ;;jump to vblank wait #1 --/
    |
    \--> clrmem:
          LDA #$FE
          STA $0200, x
          INX
          BNE clrmem

          JSR vblankwait  ;; jump to vblank wait again, returns here

Better Controller Reading
=========================

Now that you can set up subroutines, you can do much better controller
reading.  Previously the controller was read as it was processed.  With
multiple game states, that would mean many copies of the same controller
reading code.  This is replaced with one controller reading subroutine that
saves the button data into a variable.  That variable can then be checked in
many places without having to read the whole controller again::

    ReadController:
      LDA #$01
      STA $4016
      LDA #$00
      STA $4016
      LDX #$08
    ReadControllerLoop:
      LDA $4016
      LSR A           ; bit0 -> Carry
      ROL buttons     ; bit0 <- Carry
      DEX
      BNE ReadControllerLoop
      RTS

This code uses two new instructions.  The first is LSR (Logical Shift Right). 
This takes each bit in A and shifts them over 1 position to the right.  Bit 7
is filled with a 0, and bit 0 is shifted into the Carry flag::

    bit number      7 6 5 4 3 2 1 0  carry
    original data   1 0 0 1 1 0 1 1  0
                    \ \ \ \ \ \ \  \
                     \ \ \ \ \ \ \  \ 
    shifted data    0 1 0 0 1 1 0 1  1

Each bit position is a power of 2, so LSR is the same thing as divide by 2.

The next new instruction is ROL (ROtate Left) which is the opposite of LSR. 
Each bit is shifted to the left by one position.  The Carry flag is put into
bit 0.  This is the same as a multiply by 2.

These instructions are used together in a clever way for controller reading. 
When each button is read, the button data is in bit 0.  Doing the LSR puts the
button data into Carry.  Then the ROL shifts the previous button data over and
puts Carry back to bit 0.  The following diagram shows the values of
Accumulator and buttons data at each step of reading the controller:

+------------------+------------------------------------------+---------+--------------------------------------------+
|                  |   Accumulator                            |         |         buttons data                       |
+==================+===+===+===+===+===+===+===+=====+========+=========+===+===+===+===+===+===+=====+=====+========+
| bit:             | 7 | 6 | 5 | 4 | 3 | 2 | 1 |  0  |  Carry |         | 7 | 6 | 5 | 4 | 3 | 2 |  1  |  0  |  Carry |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| read button A    | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  A  |  0     |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  0  |  0     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| LSR A            | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A     |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  0  |  A     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| ROL buttons      | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A     |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A  |  0     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| read button B    | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  B  |  0     |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A  |  0     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| LSR A            | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  B     |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A  |  B     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| ROL buttons      | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  0     |         | 0 | 0 | 0 | 0 | 0 | 0 |  A  |  B  |  0     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| read button SEL  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | SEL |  0     |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A  |  0     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| LSR A            | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  0  | SEL    |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A  | SEL    |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| ROL buttons      | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  0     |         | 0 | 0 | 0 | 0 | 0 | A |  B  | SEL |  0     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| read button STA  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | STA |  0     |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A  |  0     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| LSR A            | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  0  | STA    |         | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  A  | STA    |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+
| ROL buttons      | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  0  |  0     |         | 0 | 0 | 0 | 0 | A | B | SEL | STA |  0     |
+------------------+---+---+---+---+---+---+---+-----+--------+---------+---+---+---+---+---+---+-----+-----+--------+

The loop continues for a total of 8 times to read all buttons.  When it is done
there is one button in each bit:

======= =     =   ====== =====  ==   ====  ==== =====
bit:    7     6     5     4     3     2     1     0
======= =     =   ====== =====  ==   ====  ==== =====
button: A     B   select start  up   down  left right
======= =     =   ====== =====  ==   ====  ==== =====

If the bit is 1, that button is pressed.

Game Layout
===========

The Pong game engine will use the typical simple NES game layout.  First all
the initialization is done.  This includes clearing out RAM, setting up the
PPU, and loading in the title screen graphics.  Then it enters an infinite
loop, waiting for the NMI to happen.  When the NMI hits the PPU is ready to
accept all graphics updates.  There is a short time to do these so code like
sprite DMA is done first.  When all graphics are done the actual game engine
starts.  The controllers are read, then game processing is done.  The sprite
position is updated in RAM, but does not get updated until the next NMI.  Once
the game engine has finished it goes back to the infinite loop:

.. code-block:: text

    Init Code -> Infinite Loop -> NMI -> Graphics Updates -> Read Buttons -> Game Engine --\
                       ^                                                                    |
                        \------------------------------------------------------------------/

Game State
==========

The use of a "game state" variable is a common way to arrange code.  The game
state just specifies what code should be run in the game engine each frame.  If
the game is in the title screen state, then none of the ball movement code
needs to be run.  A flow chart can be created that includes what each state
should do, and the next state that should be set when it is done.  For Pong
there are just 3 basic states:

.. code-block:: text

     ->Title State              /--> Playing State            /-->  Game Over State
    /  wait for start button --/     move ball               /      wait for start button -\
    |                                move paddles           |                               \
    |                                check for collisions   /                               |
    |                                check for score = 15 -/                                |
     \                                                                                     /
      \-----------------------------------------------------------------------------------/ 


The next step is to add much more detail to each state to figure out exactly
what is needed.  These layouts are done before any significant coding starts. 
Some of the game engine like the second player and the score will be added
later.  Without the score there is no way to get to the Game Over State yet

.. code-block:: text

    Title State:
      if start button pressed
        turn screen off
        load game screen
        set paddle/ball position
        go to Playing State
        turn screen on

    Playing State:
      move ball
        if ball moving right
          add ball speed x to ball position x
          if ball x > right wall
            bounce, ball now moving left

        if ball moving left
          subtract ball speed x from ball position x
          if ball x < left wall
            bounce, ball now moving right

        if ball moving up
         subtract ball speed y from ball position y
          if ball y < top wall
            bounce, ball now moving down

        if ball moving down
          add ball speed y to ball position y
           if ball y > bottom wall
             bounce, ball now moving up

      if up button pressed
        if paddle top > top wall
          move paddle top and bottom up

      if down button pressed
        if paddle bottom < bottom wall
          move paddle top and bottom down
     
      if ball x < paddle1x
        if ball y > paddle y top
          if ball y < paddle y bottom
            bounce, ball now moving left

    Game Over State:
      if start button pressed
        turn screen off
        load title screen
        go to Title State
        turn screen on

Putting It All Together
=======================

Download and unzip the `pong1.zip
<http://www.nespowerpak.com/nesasm/pong1.zip>`__ sample files.  The playing
game state and ball movement code is in the pong1.asm file. Make sure that
file, mario.chr, and pong1.bat is in the same folder as NESASM3, then double
click on pong1.bat. That will run NESASM3 and should produce pong1.nes. Run
that NES file in FCEUXD SP to see the ball moving!

Other code segments have been set up but not yet completed.  See how many of
those you can program yourself.  The main parts missing are the paddle
movements and paddle/ball collisions.  You can also add the intro state and the
intro screen, and the playing screen using the background information from the
previous week.
