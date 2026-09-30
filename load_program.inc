; This is where you define the program you want to be in the ROM and the keybinds associated.

; Put the name of the file you want to load as the program here.
def PROGRAM		equs "\"\""

; Define the CHIP-8 key you want assigned to each button.
; The input should be exactly one nibble in size ($00 - $0F).
; Anything larger will result in nothing being assigned to that key.
def KEY_RIGHT	equ $FF
def KEY_LEFT	equ $FF
def KEY_UP		equ $FF
def KEY_DOWN	equ $FF
def KEY_A		equ $FF
def KEY_B		equ $FF
def KEY_SEL		equ $FF
def KEY_START	equ $FF

; This is an example of what loading a program might look like.
;
;	; Put the name of the file you want to load as the program here.
;	def PROGRAM		equs "\"program.ch8\""	; The name of the program inside of the back slashes and quotations.
;
;	; Define the CHIP-8 key you want assigned to each button.
;	; The input should be exactly one nibble in size ($00 - $0F).
;	; Anything larger will result in nothing being assigned to that key.
;	def KEY_RIGHT		equ $9				; Set to a single hex number.
;	def KEY_LEFT		equ $7
;	def KEY_UP			equ $5
;	def KEY_DOWN		equ $8
;	def KEY_A			equ $6
;	def KEY_B			equ $FF				; Set to $FF to say unset.
; 	def KEY_SEL			equ $FF
;	def KEY_START		equ $FF
;
; The key binds in this example program work for most of the CHIP-8 programs made with Octo.