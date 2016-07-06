; ********************************************************************************************************************
; ********************************************************************************************************************
;
;													Core code 
;													=========
;	
;	This is the code that is mandatory : boot up code, short call handler, short register loader, interrupt routine.
;	anything else is optional.
;
; ********************************************************************************************************************
; ********************************************************************************************************************

	cpu 	1802

r0 = 0 																		; DMA for video / keyboard
r1 = 1 																		; Interrupt routine
r2 = 2 																		; Stack
r3 = 3 																		; Normal Running Register

r4 = 4 																		; user registers (r4 - ra)
r5 = 5
r6 = 6
r7 = 7
r8 = 8
r9 = 9
ra = 10

rb = 11 																	; RB.0 RB.1 RC.0 changed by vcall and lrs.
rc = 12 																	; RC.1 current key press $FF none
rd = 13 																	; address of video RAM
re = 14 																	; call handler
rf = 15 																	; 3 byte 16 bit register loader.

; ********************************************************************************************************************
;
;													Relevant constants
;
; ********************************************************************************************************************

controlPort = 2 															; control port (bit 7 sound, 0/1 row/col)
videoRAMSize = scWidth * scHeight / 8 										; amount of RAM allocated to memory.
videoControlBits = (scWidth/64)+(scHeight/32)*2 							; bits written to video control port.

; ********************************************************************************************************************
;
;														Various Macros
;
; ********************************************************************************************************************

lrs macro 	register,value 													; load register slow 12 bit.
	sep 	rf
	db 		((register)*16)+(((value) / 256) & 15)
	db 		(value) & 255
	endm

vCall macro function 														; call given routine by number
	sep 	re
	db 		function
	endm

vReturn macro 																; return from routine is VCALL 0
	vCall	0 																
	endm

; ********************************************************************************************************************
;
; 	Start up first part. Runs in P = 0 X = 0. Sets up Stack (R2) Interrupt (R1) RegLoader (RF) then loads P3
;	and goes to X = 2 P = 3 with interrupts enabled.
;
; ********************************************************************************************************************

	dis 																	; disable interrupts
	db 		00h
	ldi 	(memorySize-videoRAMSize) / 256 								; set up R2 (stack) and RD (video ram addr)
	phi 	r2 																; which are the same value.
	phi 	rd 																; stack down, video memory up.
	ldi 	(memorySize-videoRAMSize) & 255 	
	plo 	r2
	plo 	rd

	ghi 	r0 																; set up RF (12 bit register loader function)
	phi 	rf 																; and R1 (interrupt handler)
	phi 	re 																; and RE (call function)
	phi 	r1 																; all of which are in page zero.
	ldi 	regLoader & 255
	plo 	rf
	ldi 	interrupt & 255
	plo 	r1
	ldi 	callHandler & 255
	plo 	re

	ldi 	0FFh 															; clear keyboard read flag RC.1 to no key.
	phi 	rc

	out 	controlPort 													; write to control port 	
	db 		videoControlBits 												; the video setup.

	ldi 	main / 256 														; R3 = main program (may not be on this page)
	phi 	r3
	ldi 	main & 255
	plo 	r3
	ret  																	; now run in R3, set X=2 and enable interrupts.
	db 		023h


; ********************************************************************************************************************
;
;											Table of word addresses to routines
;
; ********************************************************************************************************************

	include vector.mod 														; this table is generated.

; ********************************************************************************************************************
;
;	Slow compact Rn loader. Uses RF. Following 2 bytes have the register number in the upper 4 bits
; 	and a 12 bit value to load in the lower 4 bites. Preserves D but not DF. Reentrant.
;
;	Code which needs to be executed quickly should consider the LDI/PHI/LDI/PLO sequence - this is 4-5 times
; 	slower but uses 3 bytes not 6. 80:20 rule.
;
;	 										THIS CODE IS SELF MODIFYING
; ********************************************************************************************************************

regLoader:
	plo 	rc 																; preserve D
	ghi 	rf 																; point RB to self modifying code
	phi 	rb
	ldi 	regLoader_putHigh 
	plo 	rb
	lda 	r3 																; get reg number / upper 4 bits
	dec 	r3 																; unpick increment
	shr 																	; isolate bits 4..7, register number.
	shr
	shr
	shr
	ori 	0B0h 															; make it PHI <register number>
	str 	rb 																; save at "PHI" point
	inc 	rb 																; advance RF to "PLO" point
	inc 	rb
	xri 	010h 															; make it PLO <register number>
	str 	rb 																; save at "PLO" point
	lda 	r3 																; reload first byte
	ani 	0Fh 															; only want lower 4 bits
regLoader_putHigh:
	phi 	0 																; these two phi and plo are modified.
	lda 	r3
	plo 	0
	glo 	rc 																; restore D
	sep 	r3 																; return and re-enter
	br 		regLoader  														

; ********************************************************************************************************************
;
;	Interrupt handler. Sets up R0 with the value held in RD (Video Memory pointer). If R0 is $01 or $81 on
; 	entry then it assumes a DMA In has been done and copies the byte before into RC.1
;
; ********************************************************************************************************************

interrupt:
	dec 	r2 																; save XP on stack.
	sav
	dec 	r2 																; save D on stack
	str 	r2
	glo 	r0 																; look at R0 bits 0..6
	ani 	7Fh
	xri 	01h
	bnz 	interrupt_nokey 												; if $01 then DMA was done this frame
	dec 	r0 																; get the data that was input (one byte only)
	lda 	r0
	phi 	rc 																; and save in RC.1
interrupt_nokey:
	ghi 	rd 																; copy RD (video RAM address) to R0
	phi 	r0
	glo 	rd
	plo 	r0
	lda 	r2 																; restore D
	ret 																	; restore XP
	br 		interrupt

; ********************************************************************************************************************
;
; 		Call routine where the byte after the call is the address in page 0 of the new routine. If the byte is
;		zero, then this is a return from a caller. Preserves D and DF on call or return.
;
; ********************************************************************************************************************

callHandler:
	plo 	rc 																; save D register
	lda 	r3 																; read the function number
	bz 		__callHandler_Return 											; if zero, then do a return.
	plo 	rb 																; save in RD.0
	ghi 	re 																; make RD.1 point to zero page
	phi 	rb

	ghi 	r3 																; push R3.1 on the stack
	dec 	r2
	str 	r2
	glo 	r3 																; push R3.0 on the stack.
	dec 	r2
	str 	r2

	lda 	rb 																; read routine address into R3
	phi 	r3
	lda 	rb 	
	plo 	r3

__callHandler_Exit:
	glo 	rc 																; restore D register
	sep 	r3 																; switch back to R3
	br 		callHandler

__callHandler_Return:
	lda 	r2 																; pop return address, then restore D and switch
	plo 	r3
	lda 	r2
	phi 	r3
	br 		__callHandler_Exit

; ********************************************************************************************************************
;
;												Included fonts, if any
;
; ********************************************************************************************************************
	
	include font.mod 														; any fonts requested loaded here.

