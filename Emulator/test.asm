
	cpu 	1802
	
r0 = 0
r1 = 1
r2 = 2
r3 = 3
r4 = 4
r5 = 5
r6 = 6

screen = 0700h

	idl																		; switch to P = 3
	ghi 	r0
	phi 	r3
	ldi 	start & 255
	plo 	r3
	sep 	r3
start:
	ldi 	6 																; set stack to 6FFh
	phi 	r2
	ldi 	0FFh
	plo 	r2

	ldi 	screen/256														; R0 points to screen
	phi 	r0
	ldi 	0
	plo 	r0
	phi 	r1 																; set interrupt
	ldi 	interruptRoutine & 255
	plo 	r1

	sex 	r3 																; X = P = 3
	out 	1
	db 		2 																; select device 2
	out 	2
	db 	 	3 																; command 3 (TV on)

	out 	1  																; select device 1
	db 		1
	out 	2 																; command 1 (keypad on)
	db 		1

	ldi 	0C0h 															; set R4 to 0xC0
	plo 	r4
	ghi 	r0
	phi 	r4

loop:
	bn1 	loop 															; wait for key press
wait:
	sex 	r2
	db 		068h 															; INP 0 reads it to M(2)
	lda 	r2																; read it.
	dec 	r2
	str 	r4 																; copy to R4.
	inc 	r4
	br 		loop

interruptExit:
	lda 	r2 																; restore D and return.
	ret 
interruptRoutine:
	dec 	r2 																; save XP on stack
	sav 
	dec 	r2 																; save D on stack.
	str 	r2
	ldi 	screen/256														; reset screen address
	phi 	r0
	ldi 	0
	plo 	r0
	br 		interruptExit




