; ********************************************************************************************************************
; ********************************************************************************************************************
;
;													Test File
;
; ********************************************************************************************************************
; ********************************************************************************************************************

scWidth = 64 																; screen dimensions.
scHeight = 32
memorySize = 4096 															; memory size built for.

font = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" 								; what characters are being used.

	include core.asm

	ldi 	0 																; page 0 = vram so we can see what's happening.
	phi 	rd
	plo 	rd

loop:
	sep 	re
	db 		C_Test
	ghi 	rd 																; copy keyboard in to display further down.
	phi 	r4
	glo 	rd
	adi 	0C0h
	plo 	r4
	ghi 	rc
	str 	r4
	inc 	r4
	inc 	r4
	glo 	r8
	str 	r4
	br 		loop

FUNC_test:
	inc 	r8
	sep 	re
	db 		00

