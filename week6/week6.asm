; vim: ft=asm_ca65

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
end_palette:
s_palette = (end_palette - palette)
rosprites:
     ;vert tile attr horiz
    .byte $80, $32, $00, $80   ;sprite 0
    .byte $80, $33, $00, $88   ;sprite 1
    .byte $88, $34, $00, $80   ;sprite 2
    .byte $88, $35, $00, $88   ;sprite 3
end_rosprites:
s_rosprites = (end_rosprites - rosprites)
background:
sky = $24
bricktop = $45
brickbottom = $47
qblock = $53
    .res $20, sky  ;;row 1, all sky
    .res $20, sky  ;;row 2, all sky

    .byte sky,sky,sky,sky,bricktop,bricktop,sky,sky
    .byte bricktop,bricktop,bricktop,bricktop,bricktop,bricktop,sky,sky  ;;row 3
    .byte sky,sky,sky,sky,sky,sky,sky,sky
    .byte sky,sky,sky,sky,qblock,qblock+1,sky,sky  ;;some brick tops
    
    .byte sky,sky,sky,sky,brickbottom,brickbottom,sky,sky
    .byte brickbottom,brickbottom,brickbottom,brickbottom,brickbottom,brickbottom,sky,sky  ;;row 4
    .byte sky,sky,sky,sky,sky,sky,sky,sky
    .byte sky,sky,sky,sky,qblock+2,qblock+3,sky,sky  ;;brick bottoms

end_background:
s_background = (end_background - background)
attribute:
    .byte %00000000, %00010000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000
    
end_attribute:
s_attribute = (end_attribute - attribute)
.segment "OAM"
sprites:
    .res $10, $00
.segment "ZEROPAGE"
playerpos:
    .res $02, $00
buttons:
    .res $01, $00

.segment "CODE"

BUTTON_A = %10000000
BUTTON_B = %01000000
BUTTON_SELECT = %00100000
BUTTON_START = %00010000
BUTTON_UP = %00001000
BUTTON_DOWN = %00000100
BUTTON_LEFT = %00000010
BUTTON_RIGHT = %00000001

vblankwait:
    bit $2002
    bpl vblankwait
    rts

ReadController:
    lda #$01 ;latch the controller
    sta $4016
    lda #$00
    sta $4016
    ldx #$08
@loop:
    lda $4016
    lsr A           ; bit0 -> Carry
    rol buttons     ; bit0 <- Carry
    dex
    bne @loop
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
    cpx #s_palette              ; compare x to hex $10, decimal 16 - copying 16 bytes = 4 sprites
    bne loadpalettesloop  ; branch to loadpalettesloop if compare was not equal to zero
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
                        
    lda #$80 ;set up player position
    sta playerpos
    sta playerpos+1
              
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
    cpx #s_background              ; compare x to hex $80, decimal 128 - copying 128 bytes
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
    cpx #s_attribute              ; compare x to hex $08, decimal 8 - copying 8 bytes
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
    lda #>sprites
    sta $4014       ; set the high byte (02) of the ram address, start the transfer

    ; Read controller input and update positions
    jsr ReadController

    lda buttons
    and #BUTTON_UP
    beq :+
    dec playerpos+1
:
    lda buttons
    and #BUTTON_DOWN
    beq :+
    inc playerpos+1
:
    lda buttons
    and #BUTTON_LEFT
    beq :+
    dec playerpos
:
    lda buttons
    and #BUTTON_RIGHT
    beq :+
    inc playerpos
:
    ; We update the sprite positions here
    lda playerpos+1 ;vertical first
    ; Sprites 0 and 1
    sta sprites
    sta sprites+4
    clc
    ; Sprites 2 and 3 (shifted down)
    adc #$08
    sta sprites+8
    sta sprites+12

    ; Sprites 0 and 2
    lda playerpos ;horizontal
    sta sprites+3
    sta sprites+11
    clc
    ; Sprites 1 and 3 (shifted right)
    adc #$08
    sta sprites+7
    sta sprites+15


    ;;this is the ppu clean up section, so rendering the next frame starts properly.
    lda #%10010000   ; enable nmi, sprites from pattern table 0, background from pattern table 1
    sta $2000
    lda #%00011110   ; enable sprites, enable background, no clipping on left side
    sta $2001
    lda #$00        ;;tell the ppu there is no background scrolling
    sta $2005
    sta $2005
  
    rti             ; return from interrupt
