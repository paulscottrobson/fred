
	cpu 	1802
	
r0 = 0
r1 = 1
r2 = 2
r3 = 3
r4 = 4
r5 = 5
r6 = 6
rd = 13
re = 14
rf = 15

stack_start = 02FFh
video_ram = 0000h

	dis 	
	db 		0
	br 		boot
;
;	Call and system vectors here.
;
S_Return: 															; these vectors will be auto generated
	dw		FUNC_Return
S_GetKey:
	dw 		FUNC_GetKey
S_Test:
	dw 		FUNC_Test
;
;	Start up.
;
boot:
	ldi 	stack_start / 256 										; set up stack
	phi 	r2
	ldi 	stack_start & 255
	plo 	r2
	sex 	r2 														; R2 is now an index register
	ghi 	r0 														; R0.1 = 0
	phi 	r3
	phi 	re
	ldi 	call_handler & 255 										; RE points to the call routine.
	plo 	re
	ldi 	boot_switch_r3 & 255 									; Make us run in R3.
	plo 	r3
	sep 	r3 														; run in R3
boot_switch_r3:
	sep 	re 														; load R1 with interrupt routine.
	db 		080h+1*8+(interrupt / 256)
	db 		(interrupt & 255)
	ghi 	r3 														; zero R0, stops initial DMA In detect on 1st interrupt
	plo 	r0
	ldi 	023h 													; turn interrupts on.
	dec 	r2
	str 	r2
	ret
	br 		main 

; ***********************************************************************************************************
;
;	CALL routine. Following byte contains a command function 00-7E which is an index into
; 	memory at [x]. So SEP RE ; DB 4  reads the call address from locations 4 and 5.
;	
;	For 80-FF it is a 2 byte instruction which loads bits 0-10 into a register specified by
;	bit 11-14.
;
;	e.g. 
;
; 	SEP RE ; 0 a6 a5 a4 a3 a2 a1 a0 							Indirect subroutine call at [a]
;	SEP RE ; 1 r3 r2 r1 r0 d10 d9 d8 ; d7 d6 d5 d4 d3 d2 d1 d0 	Load 16 bit register
;
;	Only works when running in R3.
; ***********************************************************************************************************

call_handler:
	plo 	rd 					; save D
	lda 	r3 					; get function #
	ani 	80h 				; check bit 7
	bnz 	call_load_register 	; load register call.
	dec 	r3 					; reload it.
	lda 	r3
	plo 	rf 					; save in RF.0

	glo 	r3 					; push return.0
	dec 	r2
	str 	r2
	ghi 	r3 					; push return.1
	dec 	r2
	str 	r2

	ldi 	0 					; RF points to jump table in page $00
	phi 	rf
	lda 	rf 					; read jump address into R3
	phi 	r3
	lda 	rf
	plo 	r3
	glo 	rd 					; restore D
	sep 	r3 					; and go there
	br 		call_handler 		; make re-entrant

call_load_register:
	dec 	r3 					; point back at original value.
	ghi 	re 					; get the current page into RF.1
	phi 	rf
	ldi 	call_putH 			; point RF to the PLO instruction.
	plo 	rf
	lda 	r3 					; get the Register number
	shr 						; get bits 11-14 into bits 0-3
	shr
	shr
	ani 	0Fh
	ori 	0B0h 				; make into PHI Rn
	str 	rf 					; save at RF
	inc 	rf 					; point to the PLO
	inc 	rf 
	xri 	010h 				; make it PLO Rn
	str 	rf 					; update the code.
	dec 	r3 					; reget the first byte
	lda 	r3
	ani 	07h 				; lower 3 bits only.
call_putH:
	phi 	r0 					; do the actual load.
	lda 	r3
	plo 	r0
	glo 	rd 					; restore D
	sep 	r3 					; return
	br 		call_handler

; ***********************************************************************************************************
;
;											System call which does return
;
; ***********************************************************************************************************

FUNC_Return:
	plo 	rd 					; save return value in RD.0
	ghi 	r3  				; switch back to running same code in RF so we can change R3
	phi 	rf
	ldi 	return_main & 255
	plo 	rf
	sep 	rf
return_main:
	inc 	r2 					; get and throw the call-to-return (this is run in R3)
	inc 	r2
	lda 	r2 					; fetch return.1
	phi 	r3
	lda 	r2					; fetch return.0
	plo 	r3
	glo 	rd 					; restore return value
	sep 	r3 					; and go there in R3

FUNC_GetKey:
	ldi 	00
	sep 	re
	db 		S_Return

; ***********************************************************************************************************
;
;					Standard interrupt routine. Called on VSync so not time critical.
;
; ***********************************************************************************************************

interrupt:
	dec 	r2 														; save XP
	sav
	dec 	r2 														; save D
	str 	r2
	glo 	r0 														; if odd DMA In has been received
	ani 	1 														; (this depends on R0 being set as even)
	bz 		int_nokey
	dec 	r0 														; get pressed key
	lda 	r0
	dec  	r2
	str 	r2 														; save on stack
	ghi 	r1 														; point R0 to the operand of LDI in FUNC_GetKey
	phi 	r0 
	ldi 	(FUNC_GetKey+1) & 255
	plo 	r0
	lda 	r2 														; get key off stack and write.
	str 	r0 
int_nokey:
	ldi 	video_ram / 256 										; set up R0 for rendering.																
	phi 	r0	
	ldi 	video_ram & 255 
	plo 	r0

	lda 	r2 														; restore D X P and Return
	ret
	br 		interrupt

main:
	sep 	re
	db 		S_Test

	ldi 	0FFh
	plo 	r5

wait:
	ghi 	r3
	phi 	r4
	ldi 	226
	plo 	r4
	lda 	r4
	dec 	r4
	adi 	1
	str 	r4
	inc 	r4
	inc 	r4

	sep 	re
	db 		S_GetKey
	str 	r4

	ghi 	r1
	phi 	r6
	ldi 	42
	plo 	r6
__Delay:
	dec 	r6 					; 6 x 42 = 252 instructions = 4032 cycles. = 8064 cycles per tick, 1000000 / 8064 = 124Hz.
	glo 	r6
	bnz 	__Delay

	br 		wait

FUNC_test:
	sep 	re
	db 		S_Return
	