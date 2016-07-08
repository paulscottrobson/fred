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

	include core.asm 														; install FredOS :)

main:
	sound 	220,1000
	sound 	440,500

loop:
	vcall  	C_ClearScreen
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