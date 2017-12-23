; vim: ft=asm_ca65

.segment "CHARS"
    .incbin "mario.chr" ; if you have one
.segment "HEADER"
    .byte "NES",26,2,1 ; 32K PRG, 8K CHR
.segment "VECTORS"
    .word nmi, reset, 0
.segment "RODATA"
palette:
    .byte $0F,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
    .byte $0F,$05,$28,$08,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
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
    sei
    cld
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
    lda $2002    ; read PPU status to reset the high/low latch
    lda #$3F
    sta $2006    ; write the high byte of $3F00 address
    lda #$00
    sta $2006    ; write the low byte of $3F00 address
    ldx #$00
@loop:
    lda palette, x        ;load palette byte
    sta $2007             ;write to PPU
    inx                   ;set index to next byte
    cpx #s_palette
    bne @loop  ;if x = $20, 32 bytes copied, all done

LoadSprites:
    ldx #$00              ; start at 0
@loop:
    lda rosprites, x        ; load data from address (sprites +  x)
    sta sprites, x          ; store into RAM address ($0200 + x)
    inx                   ; X = X + 1
    cpx #s_rosprites              ; Compare X to hex $20, decimal 32
    bne @loop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                          ; if compare was equal to 32, keep going down

    lda #$80 ;set up player position
    sta playerpos
    sta playerpos+1


    lda #%10000000   ; enable NMI, sprites from Pattern Table 1
    sta $2000

    lda #%00010000   ; enable sprites
    sta $2001

forever:
    jmp forever



nmi:
    ; Load sprites early in vblank to avoid issues
    lda #$00
    sta $2003       ; set the low byte (00) of the RAM address
    lda #>sprites
    sta $4014       ; set the high byte (02) of the RAM address, start the transfer

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

    rti             ; return from interrupt
