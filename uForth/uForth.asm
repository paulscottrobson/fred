; *********************************************************************************************************************
; *********************************************************************************************************************
;
;		Core Runtime and Interpreter. Has a collection of 1801 code primitives, the bytecode interpreter and
;		the FRED display driver. 
;
;		Words in core are indicated by double square brackets in the comments, and are extracted from the list file.
; 		(so memory is not wasted storing the word name)
;
; *********************************************************************************************************************
; *********************************************************************************************************************

		cpu 1802 									; actually it is a 1801.

r0 = 0 												; display pointer (R0)
rInterrupt = 1 										; interrupt address (R1)
rRStack = 2 										; return stack (R2)
rDStack = 3 										; data stack (R3)
rProgram = 4 										; program code pointer (R4)
rVariables = 5 										; points to variables (R5)

r6 = 6												; work registers (R6-R10, can also use RE)
r7 = 7
r8 = 8
r9 = 9
ra = 10

rCounter = 11 										; interrupt counter (RB, bumps every tick)
rc = 12 											; execute instruction at r4
rd = 13 											; makes instruction byte code
re = 14 											; general temporary register
rf = 15 											; pc register when running 1801 code.

lri 	macro r,n 									; macro to load register.
		ldi (n) & 255
		plo r
		ldi (n) / 256
		phi r
		endm

videoMemory = 0700h 								; 64 x 32 Video RAM. Data memory is in the page below.
dataMemory = 0600h									; data memory page.

		br 		Boot 								; [[;]] skip over machine code. Also defines return (;) as $00

; *********************************************************************************************************************
;
;								Forth 1801 assembler primitives (optimisable for 1802)
;
;	@,!,+!,1+,1-,2*,2/,+,-,and,or,xor,literal,drop,dup,over,0-,0=,0<,0,1,-1,swap,R>,>R,0>,0BR,;,?DUP,ROT,0>,=,Pick
;	br,varpage,page!
; *********************************************************************************************************************
;					Note some of these drop through, so the order is important in some cases
;	When changing this code check the position of the GHI R0s in Boot, the first must be in page 0 the second 
;   in page 1.
; *********************************************************************************************************************

FW_In:	ldi 	068h								; [[PORT>]] input from port
		br 		FW_IO
FW_Out:	ldi 	060h 								; [[>PORT]] output to port.

FW_IO:	plo 	re 									; save in RE.0

		dec 	rRStack	 							; push $DC (SEP RC) on return stack.
		ldi 	0DCh 								
		str 	rRStack

		glo 	re 									; get instruction base (INP or OUT)
		or 											; or with the port number
		dec 	rRStack 							; push on rstack
		str 	rRStack

		ani 	008h 								; if IN, we need the old stack element for the result so we don't 
		bnz 	__IO_DoIt 							; do this INC, which is throwing away the port address
		inc 	rDStack 							; for OUT this leaves the data to be outed which post increments
__IO_DoIt:
		sep 	rRStack 							; run the code on the stack.

; *********************************************************************************************************************

FW_Pick:
		glo 	rDStack								; add TOS to DStack into RE
		add 
		plo 	re
		ghi 	rDStack
		phi 	re
		lda 	re 									; get the picked value
		str 	rDStack 							; save at TOS
		sep 	rc 									; and exit

; *********************************************************************************************************************

FW_ROT:												; [[ROT]] rotate top 3 n1 n2 n3 -> n2 n3 n1
		lda 	rDStack 							; get n3
		plo 	re
		ldx 										; get n2
		phi 	re
		glo 	re 									; get n3
		str 	rDStack 							; save where n2 was
		inc 	rDStack 							; point to n1
		ldx 										; read n1
		plo 	re 									; save in RE.0
		ghi 	re 									; get n2
		str 	rDStack 							; save where n1 was
		dec 	rDStack 							; point r3 back to start
		dec 	rDStack
		glo 	re 									; get n1
		str 	rDStack
		sep 	rc

; *********************************************************************************************************************

FW_BR:												; [[BR]] Unconditional Branch
		lda 	rProgram 							; read offset
		br 		__Branch 							; jump into 0BR after the tos = 0 test

; *********************************************************************************************************************

FW_0BR: 											; [[0BR]] if pop = 0 then advance by <next> (7 bit signed)
		lda 	rProgram 							; read offset into RE.0
		plo 	re 

		lda 	rDStack 							; pop value off top of stack
		bnz 	__Return 							; if non zero, fail. 

		glo 	re 									; put value onto the data stack as a temporary measure
__Branch:
		dec 	rDStack
		str 	rDStack
		ani 	080h 								; check bit 7
		bnz 	__0BR_Backwards 					; if -ve it is a backward jump.

		glo 	rProgram 							; add offset to R4/low
		add
		plo 	rProgram
		bnf 	__0BR_Exit
		ghi 	rProgram 							; add carry into R4
		adi 	1
__0BR_SaveR41Exit:
		phi 	rProgram
__0BR_Exit:
		inc 	rDStack 							; drop temp off stack
		sep 	rc

__0BR_Backwards:
		glo 	rProgram 							; subtract from R4/Low
		add 
		plo 	rProgram
		bdf 	__0BR_Exit 							; not borrow, exit.
		ghi 	rProgram 							; carry borrow through.
		smi 	1
		br 		__0BR_SaveR41Exit


; *********************************************************************************************************************

FW_FromR:											; [[R>]] return stack to data stack
		lda 	rRStack
		dec 	rDStack
		str 	rDStack
		lda 	rRStack
		br 		_PushD

; *********************************************************************************************************************

FW_ToR:												; [[>R]] data stack to return stack
		lda 	rDStack
		dec 	rRStack
		str 	rRStack
		lda 	rDStack
		dec 	rRStack
		str 	rRStack
__Return:
		sep 	rc

; *********************************************************************************************************************

FW_Read:	 										; [[@]] read from variable page.
		ldx 										; read address 
		plo 	rVariables 							; point RVariables to it
		lda 	rVariables 							; read rVariables
		dec 	rVariables 							; unpick if overflowed.
		br 		_SaveD 								; and write it out.

; *********************************************************************************************************************

FW_Store:											; [[!]] write to variable page.
		lda 	rDStack								; read address
		plo 	rVariables 							; rVariables points to it
		lda 	rDStack 							; read data
		str 	rVariables 							; write it.
		sep 	rc

; *********************************************************************************************************************

FW_AddStore:										; [[+!]] add tos to memory
		lda 	rDStack								; read address
		plo 	rVariables 							; rVariables points to it
		lda 	rDStack 							; read data
		sex 	rVariables
		add 										; add to memory
		sex 	rDStack
		str 	rVariables 							; write it.
		sep 	rc

; *********************************************************************************************************************

FW_Inc:												; [[1+]] Increment
		ldi 	1
		br 		__AddWr

; *********************************************************************************************************************

FW_Dec:												; [[1-]] Increment
		ldi 	0FFh
		br 		__AddWr

; *********************************************************************************************************************

FW_ShiftR:											; [[2/]] Shift right
		ldx  										; read it
		shr 										; shift right
		br 		_SaveD 								; write back.

; *********************************************************************************************************************

FW_ShiftL:											; [[2*]] Shift left
		ldx 										; read tos
		br 		__AddWr 							; add it to itself.

; *********************************************************************************************************************

FW_Add:												; [[+]] add top of stack values.
		lda 	rDStack 							; read TOS
__AddWr:add
		br 		_SaveD

; *********************************************************************************************************************

FW_Sub:												; [[-]] sub top of stack values.
		lda 	rDStack 							; read TOS
		sd
		br 		_SaveD

; *********************************************************************************************************************

FW_And:												; [[and]] and top of stack values.
		lda 	rDStack 							; read TOS
		and
		br 		_SaveD

; *********************************************************************************************************************

FW_Or:												; [[or]] or top of stack values.
		lda 	rDStack 							; read TOS
		or
		br 		_SaveD

; *********************************************************************************************************************

FW_Xor:												; [[xor]] xor top of stack values.
		lda 	rDStack 							; read TOS
		xor
		br 		_SaveD

; *********************************************************************************************************************

FW_Literal:											; [[LITERAL]], code loads literal to TOS
		lda 	rProgram 							; read the literal in
		br 		_PushD 								; push on stack

; *********************************************************************************************************************

FW_Drop:											; [[DROP]], drops top of stack.
		lda 	rDStack 							
		sep 	rc

; *********************************************************************************************************************

FW_QDup:											; [[?DUP]] word, duplicate if non zero else drop.
		ldx 										; look at TOS
		bz 		__Return 							; if zero leave unchanged, else drop through to DUP.

; *********************************************************************************************************************

FW_Dup:												; [[DUP]], duplicate top of stack
		ldx 										; read top of stack.
		br 		_PushD

; *********************************************************************************************************************

FW_Over:inc 	rDStack 							; [[OVER]] point to 2nd value
		ldx 										; read value
		dec 	rDStack 							; unpick increment
		br 		_PushD

; *********************************************************************************************************************

FW_Negate: 											; [[0-]] Word, negates top of stack
		lda 	rDStack
		dec 	rDStack
		sdi 	0
		br 		_SaveD

; *********************************************************************************************************************

FW_EqualZero:										; [[0=]] Word, sets to -1 if TOS zero 0 otherwise.
		lda 	rDStack 							; get TOS
		bz 		FW_Minus1 							; if zero, push -1 else push 0 (fall through)

; *********************************************************************************************************************

FW_0:	
		ghi 	rf 									; [[0]] Word, pushes 0 on stack.
		br 		_PushD

; *********************************************************************************************************************

FW_LessZero:										; [[0<]] Word, push 1 if negative else push 0
		lda 	rDStack 							; get TOS
		ani 	080h								; look at the sign bit.
		bz 		FW_0 								; if +ve push 0 else drop through and push 1.
		br 		FW_Minus1

; *********************************************************************************************************************

FW_1:	
		ldi 	1 									; [[1]] Word, pushes -1 on stack

_PushD:	dec 	rDStack 							; push on stack.
_SaveD:	str 	rDStack
		sep 	rc

; *********************************************************************************************************************

FW_GreaterZero:										; [[0>]] Word, push -1 if >0 else push 0
		lda 	rDStack 							; get value
		bz 		FW_0 								; zero returns 0
		ani 	80h									; check bit 7
		bnz 	FW_0 								; -ve returns 0

; *********************************************************************************************************************

FW_Minus1:	
		ldi 	0FFh								; [[-1]] Word, pushes -1 on stack.
		br 		_PushD

; *********************************************************************************************************************

FW_Swap:											; [[SWAP]] swap tos values.
		lda 	rDStack 							; read TOS, save in RE.0
		plo 	re
		ldx 										; read new TOS save in RE.1
		phi 	re
		glo 	re 									; get value that is written
		str 	rDStack
		ghi 	re 									; get value to push
		br 		_PushD

; *********************************************************************************************************************

FW_Equals:											; [[=]] check top two values equal
		sep 	rd
		db 		FW_Sub
		db 		FW_EqualZero
		db 		0 

; *********************************************************************************************************************

FW_VariablePage:
		ldi 	dataMemory / 256 					; [[VARPAGE]] pushes the page address of variables on the stack.
		br 		_PushD

; *********************************************************************************************************************

FM_SetVariablePage:
		lda 	rDStack 							; [[PAGE!]] sets the variable page from the default.
		phi 	rVariables
		sep 	rc

; *********************************************************************************************************************

FW_Stop:br 		FW_Stop								; [[STOP]] word

; *********************************************************************************************************************

FW_2:	ldi 	2 									; [[2]]
		br 		_PushD
FW_3:	ldi 	3 									; [[3]]
		br 		_PushD
FW_4:	ldi 	4 									; [[4]]
		br 		_PushD
FW_8:	ldi 8 										; [[8]]
		br 		_PushD
FW_10:	ldi 	10 									; [[10]]
		br 		_PushD
FW_16:	ldi 16 										; [[16]]
		br 		_PushD	
FW_100:	ldi 100 									; [[100]]
		br 		_PushD

; *********************************************************************************************************************
;
;											Start up uForth interpreter
;
; *********************************************************************************************************************

Boot:	ghi 	r0 									; reset counter
		phi 	rCounter 							
		plo 	rCounter

		ldi 	0FFh 								; reset return stack to end of data page
		plo 	rRStack
		ldi 	dataMemory / 256 					; set high address for the stacks and variable area (same page)
		phi 	rRStack											
		phi 	rDStack
		phi 	rVariables

		ghi 	r0 									; set up RF,RC,RD,R1 relies on all being in the same page as this.
		phi 	rInterrupt
		phi 	rc
		phi 	rd
		phi 	rf

		ldi 	ProgramCode & 255 					; RF now points to the address of the start
		plo 	rf
		lda 	rf 									; read start address of program into R4.
		phi 	rProgram
		lda 	rf
		plo 	rProgram 						
		lda 	rf 									; read data stack top, and set up that stack.
		plo 	rDStack

		ldi 	ExecuteCompiledWord & 255			; RC points to the code to execute the word at R4.
		plo 	rc
		ldi 	ExecuteDefinedWord & 255 			; RD points to the code to execute a new definition.
		plo 	rd
		ldi 	Interrupt & 255						; R1 points to the interrupt routine.
		plo 	rInterrupt

		sex  	rDStack 							; R3 points to data stack.
		sep 	rc 									; and start.

; *************************************************************************************************************************
;
;	Execute the word at (R4). This is either a 1 byte call (00-F7) or a 2 byte call (F8-FF) nn
;	Runs in RC.
;
; *************************************************************************************************************************

ExecuteCompiledWord:
		lda 	rProgram 							; get the next instruction to execute.
		adi 	8 									; will cause a carry (DF = 1) for F8-FF
		bdf 	ECW_LongAddress 					; which means it's a long address

		smi 	8 									; fix back to original value
		bz 		ECW_Return 							; if it was $00 that's a return.
		plo 	rf 									; put in RF.0
		ldi 	0 									; set RF.1 to zero. RF now points to $000-$0F7.
		phi 	rf 									
		sep 	rf 									; run whatever is there.
		br 		ExecuteCompiledWord 				; and when finished, do the next instruction.		
;
ECW_LongAddress:									; 11 bit address
		phi 	rf 									; it will be 00-07 after the add, so this is the upper byte in RF.1
		lda 	rProgram 							; get the lower byte
		plo 	rf 									; put in RF.0
		sep 	rf 									; run whatever is there.
		br 		ExecuteCompiledWord 				; and when finished, do the next instruction.		
;
ECW_Return:
		lda 	rRStack 							; retrieve the saved return address and put back in R4
		plo 	rProgram
		lda 	rRStack
		phi 	rProgram
		br 		ExecuteCompiledWord 				; and go do it.

; *************************************************************************************************************************
;
;	If the word executed via the SEP RFs is a compiled word, it will execute and be ended via SEP RC, which will execute
; 	the next word. 
;
;	If it is a sequence of commands the first instruction will be SEP RD, which will come here (with RF pointing to the
;	new code to execute)
;
; *************************************************************************************************************************

ExecuteDefinedWord:
		dec 	rRStack 							; push R4, the program pointer on the return stack
		ghi 	rProgram
		str 	rRStack
		dec 	rRStack
		glo 	rProgram
		str 	rRStack

		ghi 	rf 									; it was run in R4 (the SEP RD command), so RD will contain the next
		phi 	rProgram 							; instruction, which we copy into R4
		glo 	rf
		plo 	rProgram
		sep 	rc 									; and run "ExecuteCompiledWord"
		br 		ExecuteDefinedWord 					; this is re-entrant.

; *************************************************************************************************************************
;										Interrupt Routine (FRED version)
; *************************************************************************************************************************

Return:	
		lda 	rRStack 							; pop D
		ret 										; pop XP
Interrupt:
		dec 	rRStack 							; save XP
		sav
		dec 	rRStack 							; save D
		str 	rRStack

		ldi 	videoMemory & 255 					; set up R0
		plo 	r0
		ldi 	videoMemory / 256
		phi 	r0
		inc 	rCounter 							; bump the timer counter.
		br 		Return 		

; *************************************************************************************************************************
;
;										Draw Digit x y n autoreturns
;
; *************************************************************************************************************************

FW_DrawDigit:
		lda 	rDStack 							; get digit [[DIGIT]]
		dec 	rDStack
		add 										; x 2
		add 										; x 3
		str 	rDStack 									
		add 										; x 6
		adi 	FontData & 255
		plo 	rProgram
		ldi 	FontData / 256
		phi 	rProgram
		inc 	rDStack 

; *************************************************************************************************************************
;
;												Draw Sprite routine
;
;	Note: if used on a 1802 the bit shifting can be simplified using the 1802's ring shift. A 1801 only has a shift
;	right into DF, so in a 1801 you have two seperate bits of code for the 16 bit shift.
; *************************************************************************************************************************

FW_DrawSprite:										; [[SPRITE]] y x sprite
		lda 	rDStack 							; get Y
		dec 	rDStack 							; X = DStack = Y
		add 										; D = Y * 2
		str 	rDStack
		add 										; D = Y * 4
		str 	rDStack
		add 										; D = Y * 8
		plo 	r6 									; R6.0 = Y * 8
		inc 	rDStack 							; drop Y

		lda 	rDStack 							; fetch X
		phi 	r7 									; save in R7.1 this is used for the shift count.
		shr
		shr
		shr 										; divide by 8.
		dec 	rDStack 							; save on DStack address
		str 	rDStack
		glo 	r6 									; add Y * 8 to it
		add
		plo 	r6 									
		ldi 	videoMemory / 256 					; R6 points to video RAM write byte
		phi 	r6

		lda 	rProgram 							; get the sprite size, it is 8 x n
		plo 	r7 									; R7.0 is the count of lines.
		bz 		__SDExit 							; if line count is zero exit.
		sex 	r6 									; we use X = 6 to access video memory.
__SDLineLoop:

		lda 	rProgram 							; R8 is the byte shifting graphic
		phi 	r8
		ldi 	0
		plo 	r8 

		ghi 	r7 									; get original X value
		ani 	7 									; look at lower 3 bits, which is the right-shift
		bz 		__SDXorScreen 						; if zero no shift required
		plo 	r9 									; R9.0 is the shift counter
__SDShiftRight:
		ghi 	r8 									; shift R8.1 right 
		shr
		phi 	r8
		bdf 	__SDShiftRight1 					; if Df set need to shift a 1 into R8.0
		glo 	r8
		shr
		br 		__SDShiftDone 
;
__SDShiftRight1: 									; we have to do it this way, 1801 as now Ring Shift
		glo 	r8 									; this one shifts a 1 in as the MSB - the code immediately
		shr 										; above shifts a 0 in as the MSB.
		ori 	080h

__SDShiftDone:
		plo 	r8 									; write low byte back
		dec 	r9 									; do it the relevant number of times.
		glo 	r9
		bnz 	__SDShiftRight

__SDXorScreen:
		ghi 	r8 									; do high byte
		xor
		str 	r6
		inc 	r6
		glo 	r8 									; do low byte.
		xor 
		str 	r6

		glo 	r6 									; next line down.
		adi 	7
		plo 	r6

		dec 	r7 									; decrement line count.
		glo 	r7
		bnz 		__SDLineLoop

__SDExit:
		ldi 	ECW_Return & 255					; this forces a RETURN to be executed
		plo 	rc
		sex 	rDStack 							; X is back at rDStack
		inc 	rDStack 							; fix up data stack.
		sep 	rc

; *************************************************************************************************************************
;
;														FontData
;
; *************************************************************************************************************************

FontData:
		db 	5,070h,088h,088h,088h,070h 				; 0
		db 	5,020h,060h,020h,020h,0F8h 				; 1
		db 	5,0F0h,008h,070h,080h,0F8h 				; 2
		db 	5,070h,088h,038h,088h,070h 				; 3
		db 	5,030h,050h,0F8h,010h,010h 				; 4
		db 	5,0F8h,080h,0F0h,008h,0F0h 				; 5
		db 	5,070h,080h,0F0h,088h,070h 				; 6
		db 	5,0F8h,008h,010h,020h,040h 				; 7
		db 	5,070h,088h,070h,088h,070h 				; 8
		db 	5,070h,088h,078h,008h,070h 				; 9

; *************************************************************************************************************************
;
;		The first three bytes are the address of the first word to run, and the data stack initial value.
;
; *************************************************************************************************************************

ProgramCode:
		dw 		Start 								; [[$$STARTMARKER]] address of program start, not actually a word that can be called.
		db 		0A0h 								; data stack starts here in variable page (and works down)

; *************************************************************************************************************************
;
;											Put any long words at this point
;
; *************************************************************************************************************************

Start:												; [[$$TOPKERNEL]] it will trim these off.
		db  FW_2,FW_1,FW_Out 						; screen on.
		db 	FW_3,FW_2,FW_Out

		db 	FW_Literal,1,FW_Literal,1,FW_Literal,0
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,11,FW_Literal,1,FW_Literal,1
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,21,FW_Literal,1,FW_Literal,2
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,31,FW_Literal,1,FW_Literal,3
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,41,FW_Literal,1,FW_Literal,4
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,1,FW_Literal,11,FW_Literal,5
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,11,FW_Literal,11,FW_Literal,6
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,21,FW_Literal,11,FW_Literal,7
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,31,FW_Literal,11,FW_Literal,8
		dw 	FW_Drawer|0F800h
		db 	FW_Literal,41,FW_Literal,11,FW_Literal,9
		dw 	FW_Drawer|0F800h
		db 	FW_Stop

FW_Drawer:
		sep rd
		dw  FW_DrawDigit|0F800h
