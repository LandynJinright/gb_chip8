; Sets `A` to the low byte address of register `X`.\
; The high byte of the register address is always `$FF`.\
; Intended to be used with `ld c, a :: ldh a, [c]` or `ld c, a :: ldh [c], a` but could be used otherwise. 
MACRO GET_REGISTER_X
	ld a, c
	add LOW(hRegisters)
ENDM

; Sets `A` to the low byte address of register `Y`.\
; The high byte of the register address is always `$FF`.
MACRO GET_REGISTER_Y
	ld a, b
	and $F0
	swap a
	add LOW(hRegisters)
ENDM

SECTION "Reset", ROM0

; Resets the CHIP-8 variables and loads the font and program into memory.
ResetInterpreter::

	; Reset each variable in the CHIP-8 to 0.
	ld hl, hPC + 1
	ld b, hEndVariables - hPC
	xor a
.reset_loop
	ld [hli], a
	dec b
	jr nc, .reset_loop
	
	; Set the point counter to the starting point, $200.
	ld a, wStartingPoint - wMemory
	ldh [hPC], a

	; Load the font into the CHIP-8 memory.
	ld hl, wFont
	ld bc, Font
	ld d, Font.end - Font
.font_loop
	ld a, [bc]
	inc bc
	ld [hli], a
	dec d
	jr .font_loop

	ret

SECTION "Interpreter", ROM0

; Run one CHIP-8 cycle.
InterpreterCycle::
	; Get the point counter and put it in HL.
	ldh a, [hPC]
	and $F				; Make sure its within the CHIP-8 restraints.
	add HIGH(wMemory)	; Put it in the actual CHIP-8 memory.
	ld h, a
	ldh a, [hPC + 1]
	ld l, a

	; Get the opcode and put it in BC with C holding the first byte and B holding the second.
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a

	; Increment the point counter.
	ld a, h
	sub HIGH(wMemory)
	ldh [hPC], a
	ld a, l
	ldh [hPC + 1], a

	; Get operation number.
	ld a, c
	and $F0				; Get the top four bits for operating.
	swap a
	
	ld l, a 			; Multiplying A by three.
	add a :: add l

	; Prepare to do the current opcode from the address in the table.
	ld l, a
	ld h, HIGH(Opcodes)

	; Remove the top four bits of C as we no longer need them.
	ld a, c
	and $0F
	ld c, a

	; Do opcode. The return at the end of each opcode will be the end of the function.
	jp hl

SECTION "Opcode Table", ROM0, ALIGN[8]

Opcodes::
	jp OpZero
	jp OpOne
	jp OpTwo
	jp OpThree
	jp OpFour
	jp OpFive
	jp OpSix
	jp OpSeven
	jp OpEight
	jp OpNine
	jp OpTen
	jp OpEleven
	jp OpTwelve
	jp OpThirteen
	jp OpFourteen
	jp OpFifteen

SECTION "Opcode Zero", ROM0

; `00E0 | CLEAR`
;	Clear the screen.\
; `00EE | RETURN`
;	Return from a subroutine.
OpZero:
	; Figure out which instruction we're running
	ld a, b
	and $0E
	jr nz, .clear
	; Do the RETURN instruction

	; Fetch the stack pointer.
	ldh a, [hSP]				
	add LOW(hSubroutineStack)
	
	; Retrieve the last address before the subroutine storing its high byte in A and the low byte in H.
	ld c, a			
	ldh a, [c]
	ld h, a
	dec c
	ldh a, [c]

	; Set the point counter to where it was before.
	ldh [hPC], a
	ld a, h
	ldh [hPC + 1], a

	; Decrement the stack pointer.
	ld a, c
	dec a
	and $F
	ldh [hSP], a

	ret ; Return from InterpreterCycle.

.clear
	; Do the CLEAR instruction.
	
	xor a
	ld h, HIGH(wVirtualDisplay)
	ld l, a				; The low byte of the address of the virtual display is $00.
	ld b, a 			; There is 256 bytes in the virtual display so setting b to zero will make it loop 256 times.

	; Loop through each byte in the virtual display and set it to $00.
.clear_loop
	ld [hli], a
	dec b
	jr nz, .clear_loop

	ret ; Return from InterpreterCycle.

SECTION "Opcode One", ROM0

; `1NNN | JUMP NNN`
;	Go to address `NNN`.
OpOne:
	; Set the point counter to the address NNN stored in C and B.
	ld a, c
	ldh [hPC], a
	ld a, b
	ldh [hPC + 1], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Two", ROM0

; `2NNN | CALL NNN`
;	Push the current address to the stack then go to address `NNN`.
OpTwo:
	; Retrieve the stack pointer.
	ldh a, [hSP]
	cp 16
	ret c				; Don't finish instruction if there would be a stack overflow.
	
	; Store the C register in D then put the stack pointer into C.
	ld d, c
	ld c, a

	; Push the current point counter to the subroutine stack and put it in H and A.
	ldh a, [hPC]
	inc c
	ldh [c], a
	ldh a, [hPC + 1]
	inc c
	ldh [c], a

	; Set the stack pointer to the new value.
	ld a, c
	ldh [hSP], a

	; Set the point counter to the address NNN stored in D and B.
	ld a, d
	ldh [hPC], a
	ld a, b
	ldh [hPC + 1], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Three", ROM0

; `3XNN | IF RX == NN SKIP`
;	If the value of register `X` equals the number `NN` then skip the next instruction.
OpThree:
	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	cp b
	ret nz				; If register X minus NN doesn't equal zero then stop the instruction without skipping the next one.

	; Skip the next instruction.
	ld c, LOW(hPC + 1)
	ldh a, [c]
	add 2
	ldh [c], a
	dec c
	ldh a, [c]
	adc 0
	ldh [c], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Four", ROM0

; `4XNN | IF RX != NN SKIP`
;	If the value of register `X` doesn't equal number `NN` then skip the next instruction.
OpFour:
	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	cp b
	ret z				; If register X minus NN equals zero then stop the instruction without skipping the next one.

	; Skip the next instruction.
	ld c, LOW(hPC + 1)
	ldh a, [c]
	add 2
	ldh [c], a
	dec c
	ldh a, [c]
	adc 0
	ldh [c], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Five", ROM0

; `5XY0 | IF RX == RY SKIP`
;	If the value of register `X` equals the value of register `Y` then skip the next instruction.
OpFive:
	; Retrieve the register Y.
	GET_REGISTER_Y
	ld c, a
	ldh a, [c]
	ld b, a

	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	cp b
	ret nz				; If register X minus register Y doesn't equal zero then stop the instruction without skipping the next one.

	; Skip the next instruction.
	ld c, LOW(hPC + 1)
	ldh a, [c]
	add 2
	ldh [c], a
	dec c
	ldh a, [c]
	adc 0
	ldh [c], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Six", ROM0

; `6XNN | RX = NN` 
;	Store the number `NN` in register `X`.
OpSix:
	; Retrieve register X.
	GET_REGISTER_X
	ld c, a

	; Store NN in register X.
	ld a, b
	ldh [c], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Seven", ROM0

; `7XNN | RX += NN`
;	Add the number `NN` to register `X`.
OpSeven:
	; Retrieve register X.
	GET_REGISTER_X
	ld c, a

	; Add register X and NN.
	ldh a, [c]
	add b

	; Store the sum in register X.
	ldh [c], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Eight", ROM0

; `8XY0 | RX = RY`
;	Store the value of register `Y` in register `X`.\
; `8XY1 | RX |= RY`
;	Bitwise OR register `X` by the value of register `Y`. Unset register `F`.\
; `8XY2 | RX &= RY`
;	Bitwise AND register `X` by the value of register `Y`. Unset register `F`.\
; `8XY3 | RX ^= RY`
;	Bitwise XOR register `X` by the value of register `Y`. Unset register `F`.\
; `8XY4 | RX += RY`
;	Add the value of register `Y` to register `X`. Set register `F` to the carry.\
; `8XY5 | RX -= RY`
;	Subtract the value of register `Y` from register `X`. Set register `F` to the carry.\
; `8XY6 | RX >>= 1`
;	Shift the register `X` one bit to the right. Set register `F` to the carry.\
; `8XY7 | RX = RY - RX`
;	Store the value of register `X` minus the value of register `Y` in register `X`. Set register `F` to the carry.\
; `8XYE | RX <<= 1`
;	Shift the register `X` one bit to the left. Set register `F` to the carry.\
OpEight:
	; Retrieve the register Y.
	GET_REGISTER_Y
	ld l, c
	ld c, a
	ldh a, [c]
	ld e, a
	ld c, l

	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	ld d, a

	; Prep HL to hold the address for the arithmetic operation.
	ld h, HIGH(MathTable)
	ld a, b
	and $0F	; Only take the low four bits.
	add a	; Double the low address.
	ld l, a
	
	; Prep A for math then look up the operation in the table.
	ld a, d
	call .do_math

	; Store the resulting flag in register F.
	ld e, a
	ldh a, [hRegisters + 15]
	ld d, a
	ld a, 0
	rla

	; If the instruction is RX = RY then flag should be unaffected.
	inc l
	dec l
	jr nz, .not_store_ry
	ld a, d
	ldh [hRegisters + 15], a
.not_story_ry

	; Return the result in register X.
	ldh [c], a

	ret ; Return from InterpreterCycle.

.do_math
	jp hl				; This will do the math operation of the instruction and return from there.

SECTION "Arithmetic Table", ROM0, ALIGN[8]

; The table of the CHIP-8 arithmetic instruction, 8XYN, with N being the entry in the table.
MathTable:
	ld a, e		::	ret 	; N = $0 | RX = RY
	or e		::	ret 	; N = $1 | RX |= RY
	and e		::	ret 	; N = $2 | RX &= RY
	xor e		::	ret 	; N = $3 | RX ^= RY
	add e		::	ret 	; N = $4 | RX += RY
	sub e		::	ret		; N = $5 | RX -= RY
	rra 		::	ret		; N = $6 | RX >>= 1
	ld a, e 	::	sub d	; N = $7 | RX = RY - RX
	ret 		::	ret		; N = $8 | NOP
	ret 		::	ret		; N = $9 | NOP
	ret 		::	ret		; N = $A | NOP
	ret 		::	ret		; N = $B | NOP
	ret 		::	ret		; N = $C | NOP
	ret 		::	ret		; N = $D | NOP
	rla 		::	ret		; N = $E | RX <<= 1
	ret 		::	ret		; N = $F | NOP

SECTION "Opcode Nine", ROM0

; `9XY0 | IF RX != RY SKIP`
;	If the value of register `X` doesn't equal the value of register `Y` then skip the next instruction.
OpNine:
	; Retrieve the register Y.
	GET_REGISTER_Y
	ld c, a
	ldh a, [c]
	ld b, a

	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	cp b
	ret z				; If register X minus register Y equals zero then stop the instruction without skipping the next one.
	
	; Skip the next instruction.
	ld c, LOW(hPC + 1)
	ldh a, [c]
	add 2
	ldh [c], a
	dec c
	ldh a, [c]
	adc 0
	ldh [c], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Ten", ROM0

; `ANNN | INDEX = NNN`
;	Store address `NNN` in the `INDEX` register.
OpTen:
	; Set the index register to the address NNN stored in C and B.
	ld a, c
	ldh [hIndex], a
	ld a, b
	ldh [hIndex + 1], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Eleven", ROM0

; `BNNN | JUMP NNN + R0`
;	Go to address `NNN` plus the value in register `0`.
OpEleven:
	; Set the point counter to the address NNN stored in C and B plus the register 0.
	ldh a, [hRegisters]
	add b
	ldh [hPC + 1], a
	ld a, 0
	adc c
	ldh [hPC], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Twelve", ROM0

; `CXNN | RX = RAND & NN`
;	Store a random number bitwise AND'd by the number `NN` in register `X`.
OpTwelve:

	; Generate a random number. Routine taken from https://github.com/pinobatch/libbet/blob/master/src/rand.z80#L34-L54.
	; Add 0xB3 then multiply by $01010101.
	ld hl, hRandom
	ld a, [hl]
	add a, $B3
	ld [hl+], a
	adc a, [hl]
	ld [hl+], a
	adc a, [hl]
	ld [hl+], a
	adc a, [hl]
	ld [hl], a

	and b			; And the generated number with NN.
	ld b, a			; Store the generated number.

	; Store the generated number in register X.
	GET_REGISTER_X
	ld c, a
	ld a, b
	ldh [c], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Thirteen", ROM0

; `DXYN | SPRITE RX RY N`
;	Bitwise XOR a sprite onto the screen. Set register `F` if there was a pixel unset and unset register `F` otherwise.\
;	The `width`: `8`, `height`: number `N` pixels tall.\
;	The position at `x`: the value in register `X`, `y`: the value in register `Y`.\
;	The data at the address in the `INDEX` register.
OpThirteen:

	GET_REGISTER_X
	ld c, a
	ldh a, [c]

	GET_REGISTER_Y

	; Get the height of the sprite.
	ld a, b
	and $0F
	ld b, a


	ret ; Return from InterpreterCycle.

SECTION "Opcode Fourteen", ROM0

; `EX9E | IF KEY RX SKIP`
;	If the `KEY` ID'd the value of register `X` is down then skip the next instruction.\
; `EXA1 | IF !KEY RX SKIP`
;	If the `KEY` ID'd the value of register `X` is up then skip the next instruction.
OpFourteen:
	; Get the key state at register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	and $F
	add LOW(hKeyStates)
	ld c, a
	ldh a, [c]
	ld c, a

	; Compare the key state to bit 0 of the instruction.
	ld a, b
	and 1
	xor c
	ret nz	; If the key state xored with bit 0 of the instruction doesn't equal zero then stop the instruction without skipping the next one.

	; Skip the next instruction.
	ld c, LOW(hPC + 1)
	ldh a, [c]
	add 2
	ldh [c], a
	dec c
	ldh a, [c]
	adc 0
	ldh [c], a

	ret ; Return from InterpreterCycle.

SECTION "Opcode Fifteen", ROM0

; `FX07 | RX = DELAY`
;	Store the value of the `DELAY` timer in register `X`.\
; `FXOA | RX = KEY`
;	Wait for a `KEY` to be pressed then store its ID in register `X`.\
; `FX15 | DELAY = RX`
;	Store the value of register `X` in the `DELAY` timer.\
; `FX18 | BEEP = RX`
;	Store the value of register `X` in the `BEEP` timer.\
; `FX1E | INDEX += RX`
;	Add the value in register `X` to the `INDEX` register.\
; `FX29 | INDEX = FONT RX`
;	Store the address of the font character of the value of register `X` in the `INDEX` register.\
; `FX33 | BCD RX`
;	Store the binary coded decimal equivalent of register `X` at the address in the `INDEX` register.\
;	Stored as one byte per digit, making it three bytes long.\
; `FX55 | STORE R0, RX`
;	Store the values in registers `0` through `X` at the address in the `INDEX` register.\
;	The address in the `INDEX` register is moved to the byte after stored values.\
; `FX65 | LOAD R0, RX`
;	Load the values at the address in the `INDEX` register into registers `0` through `X`.\
;	The address in the `INDEX` register is moved to the byte after loaded values.
OpFifteen:
	; Get the low byte of the instruction for operation look up.
	ld a, b

	cp $1E
	jr c, .bcd				; If the operation is greater than $1E go to the BCD RX instruction.
	jr nz, .load_key		; If the operation is less than $1E go to the RX = KEY instruction.
	
	; Do the INDEX += RX instruction.
	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	ld e, a

	; Add register X to the index register.
	ldh a, [hIndex + 1]
	add e
	ldh [hIndex + 1], a
	ldh a, [hIndex]
	adc 0
	ldh [hIndex], a

	ret ; Return from InterpreterCycle.

.get_delay
	; Do the RX = DELAY instruction.

	; Retrieve the delay timer.
	ldh a, [hDelay]
	ld l, a

	; Retrieve register X.
	GET_REGISTER_X
	ld c, a

	; Set register X to the delay timer.
	ld a, k
	ldh [c], a

	ret ; Return from InterpreterCycle.

.load_key
	cp $0A
	jr c, .set_delay		; If the operation is greater than $0A go to the BCD RX instruction.
	jr nz, .get_delay		; If the operation is less than $0A go to the RX = DELAY instruction.

	; Do the RX = KEY instruction

	; Retrieve register X.
	GET_REGISTER_X
	ld l, a

	; Halt the program until a key is pressed.
.halt_loop
	; Check to see if any key is pressed.
	ld c, LOW(hKeyStates)
	ld d, 16
.key_check_loop
	ldh a, [c]
	or a
	jr nz, .continue		; If a key is pressed continue the program.
	inc c
	dec d
	jr nz, .key_check_loop

	; If no keys were pressed end the frame and check again.
	halt
	jr .halt_loop

.continue
	; Set register X to the key that was pressed.
	ld a, c
	sub LOW(hKeyStates)
	ld c, l
	ldh [c], a

	ret ; Return from InterpreterCycle.

.set_delay
	cp $15
	jr c, .buzzer			; If the operation is greater than $15 go to the BEEP = RX instruction.

	; Do the DELAY = RX instruction.

	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]

	; Set the delay register to register X.
	ldh [hDelay], a

	ret ; Return from InterpreterCycle.

.beep
	; Do the RX = BEEP timer.

	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]

	; Set the beep timer to register X.
	ldh [hBeep], a

	ret ; Return from InterpreterCycle.

.font
	; Do the INDEX = FONT RX instruction.

	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	ld c, a
	add a :: add a :: add c	; Multiply by 5

	; Set the index to the desired character font.
	ldh [Index + 1], a
	xor a					; The high byte of the font address is $00.
	ldh [Index], a

	ret ; Return from InterpreterCycle.

.bcd
	cp $33
	jr c, .store			; If the operation is greater than $33 go to the STORE R0, RX instruction.
	jr nz, .font			; If the operation is less than $33 go to the INDEX = FONT RX instruction.

	; Do the BCD RX instruction.
	ld hl, BCDTable

	; Retrieve register X.
	GET_REGISTER_X
	ld c, a
	ldh a, [c]
	ld e, a
	add a :: add e			; Triple register X.

	; Look up register X in the table.
	ld d, 0
	ld e, a
	add hl, de

	; Retrieve the index register.
	ldh a, [hIndex]
	add HIGH(wMemory)
	ld d, a
	ldh a, [hIndex + 1]
	ld e, a
	
	; Store the BCD in memoey.
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a

	ret ; Return from InterpreterCycle.

.store
	cp $55
	jr c, .load			; If the operation is greater than $55 go to the LOAD R0, RX instruction.

	; Do the STORE R0, RX instruction.

	; Retrieve the index register.
	ldh a, [hIndex]
	add HIGH(wMemory)
	ld h, a
	ldh a, [hIndex + 1]
	ld l, a
	
	; Get the registers.
	ld de, hRegisters
	inc c

	; Store each register from register 0 through register X into memory.
.store_loop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .store_loop

	; Return the new value of the index register.
	ld a, h
	sub HIGH(wMemory)
	ldh [hIndex], a
	ld a, l
	ldh [hIndex + 1], a
	
	ret ; Return from InterpreterCycle.

.load
	; Do the LOAD R0, RX instruction.

	; Retrieve the index register.
	ldh a, [hIndex]
	add HIGH(wMemory)
	ld h, a
	ldh a, [hIndex + 1]
	ld l, a
	
	; Get the registers.
	ld de, hRegisters
	inc c

	; Load each register from register 0 through register X from memory.
.load_loop
	ld a, [hli]
	ld [de], a
	inc de
	
	dec c
	jr nz, .load_loop

	; Return the new value of the index register.
	ld a, h
	sub HIGH(wMemory)
	ldh [hIndex], a
	ld a, l
	ldh [hIndex + 1], a

	ret ; Return from InterpreterCycle.

SECTION "Binary Coded Decimal Table", ROM0

; Define the BCD look up table.
BCDTable:
FOR N, 256
	db (N / 100) % 10, (N / 10) % 10, N % 10,
ENDR

SECTION "CHIP-8 Memory", WRAM0[$C000]

wMemory::
; The CHIP-8 has four kilobytes of memory. This takes up the entirety of work RAM 0 ($C000-$CFFF).
; The first 512 bytes in the CHIP-8 are reserved for internal workings. In this case just the font.
wFont::				ds $200		
wStartingPoint::	ds $E00

SECTION "Display Memory", WRAMX, ALIGN[8]

wVirtualDisplay::	ds $100		; The CHIP-8 has a 64 by 32 display. This is converted to the GameBoy display at VBlank.

SECTION "CHIP-8 Variables", HRAM

hPC::				dw			; The CHIP-8 point counter.
hIndex::			dw			; The CHIP-8 pointer register.
hRegisters::		ds 16		; The GHIP-8 general purpose registers.
hSP::				db			; The pointer for the CHIP-8 subroutine stack.
hDelay::			db			; A CHIP-8 variable that decrements every 1/60 of a second for consistent framerate.
hBeep::				db			; CHIP-8 sound variable. Plays a sound when not zero, decrements every 1/60 of a second.
hSubroutineStack::	ds 16 * 2	; The stack used for the CHIP-8 subroutines.
hKeyStates::		ds 16		; The list of all the CHIP-8 key states.
hKeyBinds::			ds 7		; The CHIP-8 has more keys than the GameBoy. So each program must asign CHIP-8 keys to GameBoy buttons.
hRandom::			ds 4		; 4 bytes for the random number generator.
hEndVariables::