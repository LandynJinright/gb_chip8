# CHIP-8 interpreter on the Game Boy

## How to use

You'll have to compile it yourself using the *build.sh* shell script. With the CHIP-8 program you want to run included in the ROM.

To include your program you need to edit the parameters in *load_program.inc*. The contents of which looks like:

```asm
; This is where you define the program you want to be in the ROM and the keybinds associated.

; Put the name of the file you want to load as the program here.
def PROGRAM     equs "\"\""

; Define the CHIP-8 key you want assigned to each button.
; The input should be exactly one nibble in size ($00 - $0F).
; Anything larger will result in nothing being assigned to that key.
def KEY_RIGHT   equ $FF
def KEY_LEFT    equ $FF
def KEY_UP      equ $FF
def KEY_DOWN    equ $FF
def KEY_A       equ $FF
def KEY_B       equ $FF
def KEY_SEL     equ $FF
def KEY_START   equ $FF
```

Define `PROGRAM`  as the directory of the CHIP-8 program you want.

Also the CHIP-8 has more keys then the Game Boy so we have to define the key binds also. There are 16 keys on the CHIP-8 numbered `0`-`F`. Define each Game Boy key with one of those numbers. If you want to not define a key just set it `$FF` instead.

## Design

### Registers

The original CHIP-8 on the Cosmac VIP had 16 general purpose registers which we're stored directly in the CPU's 16 registers. The Game Boy doesn't have as many registers so instead I put all the CHIP-8 registers into HRAM (along with any other variables) to use `ldh a, [c]` and `ldh [c], a` to quickly retrieve and set them.

### Framerate

The interpreter will run as many instructions as it can every frame, and because each instruction has a varing length there isn't a set number on how many instructions can run each frame. But this isn't a big deal as I haven't had the program run to slow.

Also because the interpreter tries to run as many instructions as possible the cpu never turns.

### Display

The CHIP-8 has a 64 by 32 pixel display that we can transfer to tile data. Unfortunately we can't transfer the entirety at VBlank so we have to split up the work across HBlank as well.

To avoid screen tearing any instruction that edits the display (`00E0` and `DXYN`) will check if it would be interupted by VBlank or HBlank. If it would it waits until the screen is updated.

### Keys

As stated before the CHIP-8 has 16 keys numbered `0`-`F` and the Game Boy only has 8 so we need to set key binds.

The VBlank routine is to tight to read the down keys then so they're instead read whenever an instruction needs.

### Quirks

Different versions of the CHIP-8 (e.g. the Cosmac VIP version, the HP-48 version, Octo) all have slightly different behaviors in certain instructions. We call these quirks.

This interpreter has the following quirks:

* The `RX <<= RY` and `RX >>= RY` instructions shifts register **Y** and sets register **X** to the result.
* The `LOAD` and `STORE` instructions modify the **Index** register.
* Clear the **F** register after the `RX |= RY`, `RX &= RY`, and `RX ^= RY` instructions.
* The `JUMP NNN + R0` instruction always uses register **0**.
* Sprites wrap at the screen instead of clipping.
* We don't wait for VBlank after `CLEAR` or `SPRITE RX RY N`.
