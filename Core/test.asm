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

	include core.asm 														; install FredOS :)

main:
	ldi 	020h
	phi 	ra
	ldi 	088h
	plo 	ra
	lrs 	r9,text
	vcall	C_PrintString
loop:
	br 		loop

text:
	db 		0,1,9,5,3,0FFh