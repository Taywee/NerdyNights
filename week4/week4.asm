; vim: ft=asm_ca65

.segment "CHARS"
    .incbin "mario.chr" ; if you have one
.segment "HEADER"
    .byte "NES",26,2,1 ; 32K PRG, 8K CHR
.segment "VECTORS"
    .word nmi, reset, 0
.segment "STARTUP" ; avoids warning
.segment "RODATA"
palette:
    .byte $0F,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
    .byte $0F,$05,$28,$08,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
    ;.byte $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C
.segment "ZEROPAGE"
sprite:
    .res 4 
.segment "CODE"


reset:
    sei
    cld
    ldx #$40
    stx $4017    ; disable APU frame IRQ
    ldx #$FF
    txs          ; Set up stack
    inx          ; now X = 0
    stx $2000    ; disable NMI
    stx $2001  ; disable rendering
    stx $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
    bit $2002
    bpl vblankwait1

clrmem:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$FE
    sta $0200, x
    inx
    bne clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
    bit $2002
    bpl vblankwait2

loadpalettes:
    lda $2002    ; read PPU status to reset the high/low latch
    lda #$3F
    sta $2006    ; write the high byte of $3F00 address
    lda #$00
    sta $2006    ; write the low byte of $3F00 address

    ; Set x to 0 to get ready to load relative addresses from x
    ldx #$00
LoadPalettesLoop:
    lda palette, x        ;load palette byte
    sta $2007             ;write to PPU
    inx                   ;set index to next byte
    cpx #$20            
    bne LoadPalettesLoop  ;if x = $20, 32 bytes copied, all done

    lda #$80
    sta sprite        ; put sprite 0 in center ($80) of screen vert
    sta sprite + 3        ; put sprite 0 in center ($80) of screen horiz
    lda #$00
    sta sprite + 1        ; tile number = 0
    sta sprite + 2        ; color = 0, no flipping

    lda #%10000000   ; enable NMI, sprites from Pattern Table 0
    sta $2000
    
    lda #%00010000   ; enable sprites
    sta $2001

forever:
    jmp forever

nmi:
    lda $00
    sta $2003  ; set the low byte (00) of the RAM address
    lda #>sprite
    sta $4014  ; set the high byte (02) of the RAM address, start the transfer
    
    rti        ; return from interrupt
