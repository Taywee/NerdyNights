.segment "CHARS"
    .incbin "mario.chr" ; if you have one
.segment "HEADER"
    .byte "NES",26,2,1 ; 32K PRG, 8K CHR
.segment "VECTORS"
    .word nmi, reset, 0
.segment "RODATA"
palette:
    .byte $22,$29,$1a,$0f,  $22,$36,$17,$0f,  $22,$30,$21,$0f,  $22,$27,$17,$0f   ;;background palette
    .byte $22,$1c,$15,$14,  $22,$02,$38,$3c,  $22,$1c,$15,$14,  $22,$02,$38,$3c   ;;sprite palette
rosprites:
     ;vert tile attr horiz
    .byte $80, $32, $00, $80   ;sprite 0
    .byte $80, $33, $00, $88   ;sprite 1
    .byte $88, $34, $00, $80   ;sprite 2
    .byte $88, $35, $00, $88   ;sprite 3
background:
    .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 1
    .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
    
    .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
    .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
    
    .byte $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24  ;;row 3
    .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24  ;;some brick tops
    
    .byte $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24  ;;row 4
    .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24  ;;brick bottoms
attribute:
    .byte %00000000, %00010000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000
    
    .byte $24,$24,$24,$24, $47,$47,$24,$24 ,$47,$47,$47,$47, $47,$47,$24,$24 ,$24,$24,$24,$24 ,$24,$24,$24,$24, $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms
.segment "OAM"
sprites:
    .res $10, $00

.segment "CODE"

vblankwait:
    bit $2002
    bpl vblankwait
    rts

reset:
    sei          ; disable irqs
    cld          ; disable decimal mode
    ldx #$40
    stx $4017    ; disable apu frame irq
    ldx #$ff
    txs          ; set up stack
    inx          ; now x = 0
    stx $2000    ; disable nmi
    stx $2001    ; disable rendering
    stx $4010    ; disable dmc irqs

    jsr vblankwait; first wait for vblank to make sure ppu is ready

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
   
    jsr vblankwait      ; second wait for vblank, ppu is ready after this

loadpalettes:
    lda $2002             ; read ppu status to reset the high/low latch
    lda #$3f
    sta $2006             ; write the high byte of $3f00 address
    lda #$00
    sta $2006             ; write the low byte of $3f00 address
    ldx #$00              ; start out at 0
loadpalettesloop:
  lda palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  sta $2007             ; write to ppu
  inx                   ; x = x + 1
  cpx #$20              ; compare x to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  bne loadpalettesloop  ; branch to loadpalettesloop if compare was not equal to zero
                        ; if compare was equal to 32, keep going down



loadsprites:
    ldx #$00              ; start at 0
loadspritesloop:
    lda rosprites, x        ; load data from address (sprites +  x)
    sta sprites, x          ; store into ram address ($0200 + x)
    inx                   ; x = x + 1
    cpx #$10              ; compare x to hex $10, decimal 16
    bne loadspritesloop   ; branch to loadspritesloop if compare was not equal to zero
                        ; if compare was equal to 16, keep going down
              
              
              
loadbackground:
  lda $2002             ; read ppu status to reset the high/low latch
  lda #$20
  sta $2006             ; write the high byte of $2000 address
  lda #$00
  sta $2006             ; write the low byte of $2000 address
  ldx #$00              ; start out at 0
loadbackgroundloop:
  lda background, x     ; load data from address (background + the value in x)
  sta $2007             ; write to ppu
  inx                   ; x = x + 1
  cpx #$80              ; compare x to hex $80, decimal 128 - copying 128 bytes
  bne loadbackgroundloop  ; branch to loadbackgroundloop if compare was not equal to zero
                        ; if compare was equal to 128, keep going down
              
              
loadattribute:
  lda $2002             ; read ppu status to reset the high/low latch
  lda #$23
  sta $2006             ; write the high byte of $23c0 address
  lda #$c0
  sta $2006             ; write the low byte of $23c0 address
  ldx #$00              ; start out at 0
loadattributeloop:
  lda attribute, x      ; load data from address (attribute + the value in x)
  sta $2007             ; write to ppu
  inx                   ; x = x + 1
  cpx #$08              ; compare x to hex $08, decimal 8 - copying 8 bytes
  bne loadattributeloop  ; branch to loadattributeloop if compare was not equal to zero
                        ; if compare was equal to 128, keep going down


              
              
              
  lda #%10010000   ; enable nmi, sprites from pattern table 0, background from pattern table 1
  sta $2000

  lda #%00011110   ; enable sprites, enable background, no clipping on left side
  sta $2001

forever:
  jmp forever     ;jump back to forever, infinite loop
  
 

nmi:
  lda #$00
  sta $2003       ; set the low byte (00) of the ram address
  lda #$02
  sta $4014       ; set the high byte (02) of the ram address, start the transfer


latchcontroller:
  lda #$01
  sta $4016
  lda #$00
  sta $4016       ; tell both the controllers to latch buttons


reada: 
  lda $4016       ; player 1 - a
  and #%00000001  ; only look at bit 0
  beq readadone   ; branch to readadone if button is not pressed (0)
                  ; add instructions here to do something when button is pressed (1)
  lda $0203       ; load sprite x position
  clc             ; make sure the carry flag is clear
  adc #$01        ; a = a + 1
  sta $0203       ; save sprite x position
readadone:        ; handling this button is done
  

readb: 
  lda $4016       ; player 1 - b
  and #%00000001  ; only look at bit 0
  beq readbdone   ; branch to readbdone if button is not pressed (0)
                  ; add instructions here to do something when button is pressed (1)
  lda $0203       ; load sprite x position
  sec             ; make sure carry flag is set
  sbc #$01        ; a = a - 1
  sta $0203       ; save sprite x position
readbdone:        ; handling this button is done


  ;;this is the ppu clean up section, so rendering the next frame starts properly.
  lda #%10010000   ; enable nmi, sprites from pattern table 0, background from pattern table 1
  sta $2000
  lda #%00011110   ; enable sprites, enable background, no clipping on left side
  sta $2001
  lda #$00        ;;tell the ppu there is no background scrolling
  sta $2005
  sta $2005
  
  rti             ; return from interrupt
