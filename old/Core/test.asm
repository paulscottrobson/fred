; ********************************************************************************************************************
; ********************************************************************************************************************
;
;													Test File
;
; ********************************************************************************************************************
; ********************************************************************************************************************

scWidth = 64 																; screen dimensions.
scHeight = 32

memorySize = 1024 															; memory size built for.

font = "0123456789" 														; what characters are being used.

lib_text = 1 																; use the text library and install font data
lib_sound = 1 																; use the sound library and macros
lib_graphics = 1 															; use drawing library.

	include core.asm 														; install FredOS :)

main:
	sound 	220,500
	sound 	440,250

loop:
	vcall  	C_ClearScreen
	vcall 	C_SetCursor
	db 		1,3
	ldi 	16
	vcall 	C_VLine
	vcall 	C_SetCursor
	db 		4,3
	ldi 	16
	vcall 	C_HLine

	vcall 	C_SetCursor
	db 		13,17
	lrs 	r9,text
	vcall	C_PrintString

	lrs 	r4,text+4

bump:
	lda 	r4
	dec 	r4
	adi 	1
	str 	r4
	xri 	10
	bnz 	loop
	str 	r4
	dec 	r4
	br 		bump

text:
	db 		0,0,0,0,0,0FFh