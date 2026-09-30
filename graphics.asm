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

export .end