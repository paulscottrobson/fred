; ********************************************************************************************************************
; ********************************************************************************************************************
;
;													Core code 
;													=========
;	
;	This is the code that is mandatory : boot up code, short call handler, short register loader, interrupt routine.
;	anything else is optional.
;
;	Even those it says CPU 1802, it is actually for a 1801.
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
ra = 10 																	; used as pixel position for text writing.

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
soundControlBit = 080h 														; sound control bit.

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
;						Print String at R9, terminated by $FF. On exit R9 points to byte after it.
;
; ********************************************************************************************************************

FUNC_PrintString:
	if 		lib_text
	lda 	r9 																; get character
	xri 	0FFh 															; check if end of string $FF
	bz 		__FPrint_VReturn 												; if so, go to the vreturn in print char 
	xri 	0FFh 															; fix character back
	vcall 	C_PrintChar 													; print it
	br 		FUNC_PrintString 												; and try again.
	endif

; ********************************************************************************************************************
;
;					Print character. RA is the current position (LSB is memory offset, MSB is bitmask)
;
;	uses temporary registers RC.0 and RB, also RE is used in the call but reset afterwards. RA is updated to the
; 	next space.
; ********************************************************************************************************************

FUNC_PrintChar:
	if 		lib_text
	sex 	rb 																; use RB as index register
	plo 	rc 																; save in RC.
	lrs 	re,__fontData 													; point R9 to fontdata.
__FFindCharacter:
	glo 	rc 																; character counter zero ?
	bz 		__FPrintLoop2 													; go print.
__FFindNext:
	lda 	re 																; keep advancing until and end marker (bit 0)
	shr 																	; found
	bnf 	__FFindNext
	dec 	rc 																; dec character counter e.g. found one more.
	br 		__FFindCharacter
;
;	Print next column of pixels from RE.
;
__FPrintLoop2:
	glo 	ra 																; copy current position into RB from RA.0
	plo 	rb 																; (position) and RD.1 (video high)
	ghi 	rd
	phi 	rb

	lda 	re 																; get the next byte of video data
	shr 		 															; shift right, throwing the end marker.
__FPrintLoop1:
	shr 																	; shift right and put in RC.0
	plo 	rc
	bnf 	__FPrintNoPixel 												; if 0 was shifted in.
	ghi 	ra 																; get bitmask from RA.1
	or 																		; OR into display.
	str 	rb
__FPrintNoPixel:
	glo 	rb 																; move address to next line down
	adi 	scWidth/8
	plo 	rb
	glo 	rc 																; get mask back into D.
	bnz 	__FPrintLoop1 													; back if more to print for this column.

__FPrintNext:
	ghi 	ra 																; shift RA.1 (the bitmask) right.
	shr 
	phi 	ra 
	bnf 	__FNotAdvance 													; if DF set then bit 7 of next.
	inc 	ra 																; increment RA.0 - next byte right
	ldi 	080h 															; reset mask in RA.1 to $80 (first bit)
	phi 	ra
__FNotAdvance:
	dec 	re 																; re-read last one column data
	lda 	re
	shr
	bnf 	__FPrintLoop2 													; if not first of next one, go back.
	inc 	rc 																; first time round RC.0 will be zero.
	glo 	rc 																; second time round it will be 1,
	xri 	1 																; so we do the 'next space' one more time.
	bz 		__FPrintNext
	lrs 	re,callHandler 													; reinstate RE vector.
__FPrint_VReturn:
	vReturn
	endif

; ********************************************************************************************************************
;
;													Get a key press 
;
; ********************************************************************************************************************

FUNC_GetKey:
	ghi 	rc 																; wait for RC to be not $FF
	xri 	0FFh
	bz 		FUNC_GetKey 													
																			; then fall through.

; ********************************************************************************************************************
;
;							Get any key press since last call, $FF = no key pressed
;
; ********************************************************************************************************************

FUNC_CheckKey:
	ghi 	rc 																; get key state
	plo 	rb 																; save in temp
	ldi 	0FFh 															; set key state back to $FF
	phi 	rc
	glo 	rb 																; restore key pressed.
	vReturn

; ********************************************************************************************************************
;
;													Clear Screen
;
; ********************************************************************************************************************

FUNC_ClearScreen:
	ghi 	rd 																; copy video address to RB
	phi 	rb
	glo 	rd
	plo 	rb
__ClearLoop:
	ghi 	r1
	str 	rb
	inc 	rb
	glo 	rb
	bnz 	__ClearLoop
	vReturn

; ********************************************************************************************************************
;
;					Set cursor to position in 2 bytes following call. (vCall C_SetCursor ; db x,y)
;
; ********************************************************************************************************************

FUNC_SetCursor:
	if 		lib_text
	lda 	r2 																; unstack return address to RB
	plo 	rb
	lda 	r2
	phi 	rb
	lda 	rb 																; read low then high into RA
	plo 	ra
	lda 	rb 															
	phi 	ra
	ghi 	rb 																; push address back on stack.
	dec 	r2
	str 	r2
	glo 	rb
	dec 	r2
	str 	r2
	endif

; ********************************************************************************************************************
;
;				Convert cursor position in RA (X = Low,Y = High) to screen position in RA (Byte = Low, Mask = High)
;
; ********************************************************************************************************************

FUNC_SetCursorXY:
	if 		lib_text
	sex 	r2 																; use R2 as stack.
	ghi 	ra 																; get Y position
	ani 	(scHeight-1) 													; validate it so 0-15 or 0-31
	dec 	r2
	str 	r2	
	add  																	; D = Y * 2
	str 	r2
	add 
	str 	r2 																; D = Y * 4
	if 		scWidth = 64  
	add 																	; D = Y * 8 *only* if 64 pixels per line.
	str 	r2
	endif
	glo 	ra 																; get X position
	ani 	(scWidth-1) 													; force into range 0-31 or 0-63
	shr 																	; divide by 8
	shr
	shr
	add 																	; add to Y*4 or Y*8
	str 	r2
	glo 	rd  															; get low byte of video address
	add 																	; add to result.
	str 	r2 																; save the byte position at TOS.

	ldi 	080h 															; set mask to $80
__FUNC_GetMask:
	phi 	ra
	glo 	ra 																; reached mod 8 = 0
	ani 	7
	bz 		__FUNC_GotMask 													; if so mask is correct
	dec 	ra 																; decrement X
	ghi 	ra 																; shift mask right
	shr
	br 		__FUNC_GetMask

__FUNC_GotMask:
	lda 	r2 																; pop byte position
	plo 	ra 																; to RA.0
	vReturn 																; return from subroutine
	endif

; ********************************************************************************************************************
;
;								Sound - toggle RA times with toggle time D
;
; ********************************************************************************************************************

FUNC_Sound:																
	if 		lib_sound
	plo 	rc
	ldi 	videoControlBits 												; put video control bits on stack.
	dec 	r2
	str 	r2
__SoundOuter: 																; outer loop (half cycle)
	glo 	rc 																; get loop counter [1]
	plo 	rb 																; put in temp RB.0 [2]
	sex 	r2 																; use R2 as stack [3]
	out 	controlPort 													; write to sound port [4]
	dec 	r2 																; fix up stack. [5]
	ldi 	soundControlBit 												; XOR control bit [6]
	xor 																	; [7]
	str 	r2	 															; write back [8]
__SoundInner:
	dec 	rb 																; 3 x D cycles
	glo 	rb
	bnz 	__SoundInner

	dec 	ra 																; dec counter [9]
	glo 	ra 																; check undercount [10]
	bnz 	__SoundOuter 													; loop back if not done [11]
	ghi 	ra
	bnz 	__SoundOuter  													; calc slightly out doesn't matter
	inc 	r2 																; fix up stack.
	vReturn
	endif
	
;
;	The outer loop (one half cycle = 3 x D + 11 instructions). A full cycles is twice this.
;	each instruction is 16 clocks at 1 Mhz.
;
; 	1000000 / pitch / 32 is the number of instructions per half cycle. Take away 11 (fixed)
;	and divide by 3 (loop size) for result.
;
sound macro pitch,milliseconds 
	lrs 	ra,pitch * milliseconds / 1000 * 2								; set time.
	ldi 	(1000000 / pitch / 32 - 11) / 3									; set pitch.
	vcall 	C_Sound 														; call sound routine
	endm

; ********************************************************************************************************************
;
;												Included fonts, if any
;
; ********************************************************************************************************************
	
	if 		lib_text
	include font.mod 														; any fonts requested loaded here.
	endif

; TODO: Sound Code
