; vim: ft=asm_ca65

.segment "CHARS"
    .incbin "mario.chr" ; if you have one
.segment "HEADER"
    .byte "NES",26,2,1 ; 32K PRG, 8K CHR
.segment "VECTORS"
    .word nmi, reset, 0
.segment "RODATA"
palette:
    .byte $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;;background palette
    .byte $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;;sprite palette
end_palette:
s_palette = (end_palette - palette)

rosprites:
    ;vert tile attr horiz
    .byte $80, $32, $00, $80   ;sprite 0
end_rosprites:
s_rosprites = (end_rosprites - rosprites)
.segment "OAM"
sprites:
    .res $04, $00

.segment "BSS"
gamestate:
    .res 1  ; .rs 1 means reserve one byte of space
ballx:
    .res 1  ; ball horizontal position
bally:
    .res 1  ; ball vertical position
ballup:
    .res 1  ; 1 = ball moving up
balldown:
    .res 1  ; 1 = ball moving down
ballleft:
    .res 1  ; 1 = ball moving left
ballright:
    .res 1  ; 1 = ball moving right
ballspeedx:
    .res 1  ; ball horizontal speed per frame
ballspeedy:
    .res 1  ; ball vertical speed per frame
paddle1ytop:
    .res 1  ; player 1 paddle top vertical position
paddle2ybot:
    .res 1  ; player 2 paddle bottom vertical position
buttons1:
    .res 1  ; player 1 gamepad buttons, one bit per button
buttons2:
    .res 1  ; player 2 gamepad buttons, one bit per button
score1:
    .res 1  ; player 1 score, 0-15
score2:
    .res 1  ; player 2 score, 0-15

;; DECLARE SOME CONSTANTS HERE
STATETITLE     = $00  ; displaying title screen
STATEPLAYING   = $01  ; move paddles/ball, check for collisions
STATEGAMEOVER  = $02  ; displaying game over screen
  
RIGHTWALL      = $F4  ; when ball reaches one of these, do something
TOPWALL        = $20
BOTTOMWALL     = $E0
LEFTWALL       = $04
  
PADDLE1X       = $08  ; horizontal position for paddles, doesnt move
PADDLE2X       = $F0

.segment "CODE"

vblankwait:
    bit $2002
    bpl vblankwait
    rts

reset:
    sei          ; disable IRQs
    cld          ; disable decimal mode
    ldx #$40
    stx $4017    ; disable APU frame IRQ
    ldx #$FF
    txs          ; Set up stack
    inx          ; now X = 0
    stx $2000    ; disable NMI
    stx $2001    ; disable rendering
    stx $4010    ; disable DMC IRQs

    jsr vblankwait

clrmem:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne clrmem
   
    jsr vblankwait

loadpalettes:
    lda $2002             ; read PPU status to reset the high/low latch
    lda #$3f
    sta $2006             ; write the high byte of $3F00 address
    lda #$00
    sta $2006             ; write the low byte of $3F00 address
    ldx #$00              ; start out at 0
loadpalettesloop:
    lda palette, x        ; load data from address (palette + the value in x)
                            ; 1st time through loop it will load palette+0
                            ; 2nd time through loop it will load palette+1
                            ; 3rd time through loop it will load palette+2
                            ; etc
    sta $2007             ; write to PPU
    inx                   ; X = X + 1
    cpx #s_palette              ; compare x to hex $10, decimal 16 - copying 16 bytes = 4 sprites
    bne loadpalettesloop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                          ; if compare was equal to 32, keep going down
                          
loadsprites:
    ldx #$00              ; start at 0
loadspritesloop:
    lda rosprites, x        ; load data from address (rosprites +  x)
    sta sprites, x          ; store into ram address (sprites + x)
    inx                   ; x = x + 1
    cpx #s_rosprites              ; compare x to hex $10, decimal 16
    bne loadspritesloop   ; branch to loadspritesloop if compare was not equal to zero
                        ; if compare was equal to 16, keep going down


  


;;;Set some initial ball stats
; TODO: switch this to a ROM->RAM push instead of defining in-code
    lda #$01
    sta balldown
    sta ballright
    lda #$00
    sta ballup
    sta ballleft
    
    lda #$50
    sta bally
    
    lda #$80
    sta ballx
    
    lda #$02
    sta ballspeedx
    sta ballspeedy


;;:Set starting game state
    lda #STATEPLAYING
    sta gamestate


                
    lda #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
    sta $2000

    lda #%00011110   ; enable sprites, enable background, no clipping on left side
    sta $2001

forever:
    jmp forever     ;jump back to Forever, infinite loop, waiting for NMI
  
 

nmi:
    lda #$00
    sta $2003       ; set the low byte (00) of the RAM address
    lda #>sprites
    sta $4014       ; set the high byte (02) of the RAM address, start the transfer
    
    jsr DrawScore
    
    ;;this is the PPU clean up section, so rendering the next frame starts properly.
    lda #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
    sta $2000
    lda #%00011110   ; enable sprites, enable background, no clipping on left side
    sta $2001
    lda #$00        ;;tell the ppu there is no background scrolling
    sta $2005
    sta $2005
      
    ;;;all graphics updates done by here, run game engine
    
    
    jsr ReadController1  ;;get the current button data for player 1
    jsr ReadController2  ;;get the current button data for player 2
  
GameEngine:  
    LDA gamestate
    CMP #STATETITLE
    BEQ EngineTitle    ;;game is displaying title screen
      
    LDA gamestate
    CMP #STATEGAMEOVER
    BEQ EngineGameOver  ;;game is displaying ending screen
    
    LDA gamestate
    CMP #STATEPLAYING
    BEQ EnginePlaying   ;;game is playing
GameEngineDone:  
  
  JSR UpdateSprites  ;;set ball/paddle sprites from positions

  RTI             ; return from interrupt
 
 
 
 
;;;;;;;;
 
EngineTitle:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load game screen
  ;;  set starting paddle/ball position
  ;;  go to Playing State
  ;;  turn screen on
  JMP GameEngineDone

;;;;;;;;; 
 
EngineGameOver:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load title screen
  ;;  go to Title State
  ;;  turn screen on 
  JMP GameEngineDone
 
;;;;;;;;;;;
 
EnginePlaying:

MoveBallRight:
  LDA ballright
  BEQ MoveBallRightDone   ;;if ballright=0, skip this section

  LDA ballx
  CLC
  ADC ballspeedx        ;;ballx position = ballx + ballspeedx
  STA ballx

  LDA ballx
  CMP #RIGHTWALL
  BCC MoveBallRightDone      ;;if ball x < right wall, still on screen, skip next section
  LDA #$00
  STA ballright
  LDA #$01
  STA ballleft         ;;bounce, ball now moving left
  ;;in real game, give point to player 1, reset ball
MoveBallRightDone:


MoveBallLeft:
  LDA ballleft
  BEQ MoveBallLeftDone   ;;if ballleft=0, skip this section

  LDA ballx
  SEC
  SBC ballspeedx        ;;ballx position = ballx - ballspeedx
  STA ballx

  LDA ballx
  CMP #LEFTWALL
  BCS MoveBallLeftDone      ;;if ball x > left wall, still on screen, skip next section
  LDA #$01
  STA ballright
  LDA #$00
  STA ballleft         ;;bounce, ball now moving right
  ;;in real game, give point to player 2, reset ball
MoveBallLeftDone:


MoveBallUp:
  LDA ballup
  BEQ MoveBallUpDone   ;;if ballup=0, skip this section

  LDA bally
  SEC
  SBC ballspeedy        ;;bally position = bally - ballspeedy
  STA bally

  LDA bally
  CMP #TOPWALL
  BCS MoveBallUpDone      ;;if ball y > top wall, still on screen, skip next section
  LDA #$01
  STA balldown
  LDA #$00
  STA ballup         ;;bounce, ball now moving down
MoveBallUpDone:


MoveBallDown:
  LDA balldown
  BEQ MoveBallDownDone   ;;if ballup=0, skip this section

  LDA bally
  CLC
  ADC ballspeedy        ;;bally position = bally + ballspeedy
  STA bally

  LDA bally
  CMP #BOTTOMWALL
  BCC MoveBallDownDone      ;;if ball y < bottom wall, still on screen, skip next section
  LDA #$00
  STA balldown
  LDA #$01
  STA ballup         ;;bounce, ball now moving down
MoveBallDownDone:

MovePaddleUp:
  ;;if up button pressed
  ;;  if paddle top > top wall
  ;;    move paddle top and bottom up
MovePaddleUpDone:

MovePaddleDown:
  ;;if down button pressed
  ;;  if paddle bottom < bottom wall
  ;;    move paddle top and bottom down
MovePaddleDownDone:
  
CheckPaddleCollision:
  ;;if ball x < paddle1x
  ;;  if ball y > paddle y top
  ;;    if ball y < paddle y bottom
  ;;      bounce, ball now moving left
CheckPaddleCollisionDone:

  JMP GameEngineDone
 
 
 
 
UpdateSprites:
    lda bally  ;;update all ball sprite info
    sta sprites
    
    lda #$30
    sta sprites + 1
    
    lda #$00
    sta sprites + 2
    
    lda ballx
    sta sprites + 3
    
    ;;update paddle sprites
    rts
 
 
DrawScore:
    ;;draw score on screen using background tiles
    ;;or using many sprites
    rts
 
ReadController1:
    lda #$01
    sta $4016
    lda #$00
    sta $4016
    ldx #$08
@loop:
    lda $4016
    lsr A            ; bit0 -> Carry
    rol buttons1     ; bit0 <- Carry
    dex
    bne @loop
    rts

ReadController2:
    lda #$01
    sta $4016
    lda #$00
    sta $4016
    ldx #$08
@loop:
    lda $4017
    lsr A            ; bit0 -> Carry
    rol buttons2     ; bit0 <- Carry
    dex
    bne @loop
    rts
