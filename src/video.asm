INCLUDE "src/hardware.inc"

SECTION "VBlank Interrupt", ROM0[$0040]

;  The VBlank interrupt
  push af
  push bc
  push hl
  jp VBlank

SECTION "VBlank Routine", ROM0
VBlank:
  ; Copy the virtual display data onto the screen.
  ld hl, _VRAM8800 + 296
  ld bc, wVirtualDisplay + 148
.display_loop
  ld a, [bc]
  ld [hli], a
  inc hl
  inc c
  jr nz, .display_loop
  
  ; Decrement delay counter.
  ldh a, [hDelay]
  sub 1
  adc 0
  ldh [hDelay], a

  ; Decrement the beeper.
  ldh a, [hBeep]
  sub 1
  adc 0
  ldh [hBeep], a
  jr z, .no_sound

  ; Play sound.
  ld a, $C6
  ldh [rNR24], a
  jr .after_sound
  
.no_sound
  ; Turn off the sound.
  ld a, $80
  ldh [rNR52], a
.after_sound

  ; Enable HBlank interupt.
  ld a, IEF_VBLANK | IEF_STAT
  ldh [rIE], a
  xor a
  ldh [rIF], a

  pop hl  
  pop bc
  pop af
  reti

SECTION "HBlank", ROM0[$0048]
HBlank:
  ; Check if we need to transfer display data by checking the scanline.
  push af
  ldh a, [rLY]
  cp 37
  jr nc, .dont_transfer
  push bc
  push hl

  ; Get the place data we need to transfer.
  ld b, HIGH(wVirtualDisplay)
  add a :: add a                ; The low byte of the data address is equal to the scanline times 4.
  ld c, a
  ; Get the place we need to transfer to.
  add a                         ; The low byte of the destination is twice as long as that of the source.
  ld l, a
  ld a, $88
  adc 0
  ld h, a

  ; Transfer 4 bytes of data.
  ld a, [bc]
  ld [hli], a
  inc hl
  inc c
  ld a, [bc]
  ld [hli], a
  inc hl
  inc c
  ld a, [bc]
  ld [hli], a
  inc hl
  inc c
  ld a, [bc]
  ld [hli], a
  
  pop hl
  pop bc
  pop af
  reti

.dont_transfer
  ; Since we don't need to transfer anymore display data this frame we can stop HBlank interupts.
  ld a, IEF_VBLANK
  ldh [rIE], a
  pop af
  reti