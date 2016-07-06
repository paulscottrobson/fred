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

	include core.asm

main:
	lrs 	rd,0															; use $0000 as video RAM so we can see

loop:
	vcall 	C_Test 															; call FUNC test.

	ghi 	rd 																; copy keyboard in to display further down.
	phi 	r4
	glo 	rd
	adi 	0FCh
	plo 	r4

	ghi 	rc
	str 	r4

	inc 	r4 																; write counter two further on.
	inc 	r4
	glo 	r8
	str 	r4
	br 		loop

FUNC_test:
	inc 	r8
	sep 	re
	db 		00

