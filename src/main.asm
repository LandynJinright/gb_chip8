INCLUDE "src/hardware.inc"
INCLUDE "load_program.inc"

SECTION "Header", ROM0[$0100]
  ; Start of the program. Disable interrupts then go to the entry point.
  di
  jp EntryPoint

  ; Fill space for the ROM header.
  ds $150 - @, $00

SECTION "Main", ROM0

; Starting point of the program.
EntryPoint:
	; Set up the stack.
	ld sp, wStack

	; Prepare the audio.
	ld a, $80
	ldh [rNR52], a
	ld a, $FF
	ldh [rNR51], a
	ld a, $77
	ldh [rNR50], a
	ld a, $A2
	ldh [rNR21], a
	ld a, $F0
	ldh [rNR22], a
	ld a, $00
	ldh [rNR23], a

	; Set the palette.
	ld a, %10010011
	ldh [rBGP], a
	
	; Load the program into the CHIP-8 memory.
	ld hl, Program
	ld bc, Program.end - Program
	ld de, wStartingPoint
.program_loop
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .program_loop

	; Reset each variable in the CHIP-8 to 0.
	ld hl, hPC + 1
	ld b, hEndVariables - hPC
	xor a
.reset_loop
	ld [hli], a
	dec b
	jr nz, .reset_loop
	
	; Set up the random seed.
	ld c, LOW(hRandom)
  	ld a, $F1
	ldh [c], a
  	inc c
  	ld a, $03
  	ldh [c], a
  	inc c
  	ld a, $CE
  	ldh [c], a
  	inc c
  	ld a, $3D
  	ldh [c], a

	; Set the point counter to the starting point, $200.
	ld a, HIGH(wStartingPoint - wMemory)
	ldh [hPC], a

	; Set up the key binds.
	ld c, LOW(hKeyBinds)
	ld hl, KeyBinds
	ld b, KeyBinds.end - KeyBinds
.set_key_binds
	ld a, [hli]
	cp $0F
	jr nc, .not_set
	add LOW(hKeyStates)
.key_adjusted
	ldh [c], a
	inc c
	dec b
	jr nz, .set_key_binds
	jr .after

.not_set
	xor a
	jr .key_adjusted
.after
	; Clear the CHIP-8 screen.
	ld hl, wVirtualDisplay
	ld b, 0
	xor a
.display_loop
	ld [hli], a
	dec b
	jr nz, .display_loop

	; Load the font into the CHIP-8 memory.
	ld hl, wFont
	ld bc, Font
	ld d, Font.end - Font
.font_loop
	ld a, [bc]
	inc bc
	ld [hli], a
	dec d
	jr nz, .font_loop

	; Disable LCDC to prep VRAM.
.wait_for_vblank
	ldh a, [rLY]
	cp 144
	jr nz, .wait_for_vblank
	xor a
	ldh [rLCDC], a

	; Load the barrier tiles.
	ld hl, BarrierTiles
	ld bc, BarrierTiles.end - BarrierTiles
	ld de, $8000
.barrier_tiles_loop
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .barrier_tiles_loop

	; Clear screen.
	ld hl, _VRAM8800
	ld bc, $200
.clear_screen
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, .clear_screen

	; Set up visual.
	ld hl, $9800

	; Draw the top barrier of the screen.
	ld c, 6
.top_loop
	call .blank
	dec c
	jr nz, .top_loop
	ld b, 1
	call .edge

	; Draw the screen.
	ld d, 128
	REPT 4
	call .screen_row
	ENDR

	; Draw the bottom barrier of the screen.
	ld b, 6
	call .edge
	ld c, 6
.bottom_loop
	call .blank
	dec c
	jr nz, .bottom_loop

	; Reset all objects to not cause delays.
	ld hl, STARTOF(OAM)
	ld b, 160
	xor a
.oam_clear
	ld [hli], a
	dec b
	jr nz, .oam_clear

	; Turn the LCD back on.
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
	ldh [rLCDC], a
  
	; Set up the interrupts.
	xor a
	ldh [rIF], a
	ld a, STATF_MODE00
	ldh [rSTAT], a
	ld a, IEF_VBLANK | IEF_STAT
	ldh [rIE], a
	ei
	nop

  ; Interpret forever.
.interpret_loop
	call InterpreterCycle
	jr .interpret_loop

.blank
	; Draw a blank row.
	ld e, 32
	xor a
.blank_loop
	ld [hli], a
	dec e
	jr nz, .blank_loop
	ret

.edge
	; Draw 5 blank tiles.
	xor a
	REPT 5
	ld [hli], a
	ENDR

	; Draw the left corner.
	ld a, b
	ld [hli], a

	; Draw the center edge.
	inc a
	REPT 8
	ld [hli], a
	ENDR

	; Draw the right corner.
	inc a
	ld [hli], a

	; Fill the rest of the row with blanks.
	xor a
	ld e, 17
.edge_loop
	ld [hli], a
	dec e
	jr nz, .edge_loop

	ret

.screen_row
	; Draw 5 blank tiles.
	xor a
	REPT 5
	ld [hli], a
	ENDR

	; Draw an edge tile.
	ld a, 4
	ld [hli], a

	; Draw the screnn tiles.
	ld a, d
	ld e, 8
.screen_loop
	ld [hli], a
	add 4
	dec e
	jr nz, .screen_loop
	inc d

	; Draw an edge tile
	ld a, 5
	ld [hli], a

	; Fill the rest of the row with blanks.
	xor a
	ld e, 17
.screen_edge_loop
	ld [hli], a
	dec e
	jr nz, .screen_edge_loop

	ret

SECTION "CHIP-8 Font Data", ROM0

; The font data for the CHIP-8 to use. From the original CHIP-8.
Font::
	db $F0, $90, $90, $90, $F0		; The 0 character.
	db $20, $60, $20, $20, $70		; The 1 character.
	db $F0, $10, $F0, $80, $F0		; The 2 character.
	db $F0, $10, $F0, $10, $F0		; The 3 character.
	db $90, $90, $F0, $10, $10		; The 4 character.
	db $F0, $80, $F0, $10, $F0		; The 5 character.
	db $F0, $80, $F0, $90, $F0		; The 6 character.
	db $F0, $10, $20, $40, $40		; The 7 character.
	db $F0, $90, $F0, $90, $F0		; The 8 character.
	db $F0, $90, $F0, $10, $F0		; The 9 character.
	db $F0, $90, $F0, $90, $90		; The A character.
	db $E0, $90, $E0, $90, $E0		; The B character.
	db $F0, $80, $80, $80, $F0		; The C character.
	db $E0, $90, $90, $90, $E0		; The D character.
	db $F0, $80, $F0, $80, $F0		; The E character.
	db $F0, $80, $F0, $80, $80		; The F character.

.end

SECTION "Barrier Graphics", ROM0
BarrierTiles::
	INCBIN "obj/BarrierTiles.bin"
.end

SECTION "Key Binds", ROM0

KeyBinds:
	db KEY_RIGHT, KEY_LEFT, KEY_UP, KEY_DOWN, KEY_A, KEY_B, KEY_SEL, KEY_START
.end

SECTION "Program", ROM0[$3200]
; The CHIP-8 program.
Program:
	incbin PROGRAM
.end

SECTION "Stack", WRAM0
; This is where the main stack is stored.
ds 128
wStack: