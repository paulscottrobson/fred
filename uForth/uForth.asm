;
;
;	TODO: looping code,R>,>R,ROT,PICK,R@, long fetch and store. 
;	Interrupt routine, 
;	In and Out (?)
;	0> 2 4 8 16 ?DUP = PICK
;   Start address needs redoing.
;
;
		cpu 1802 									; actually it is a 1801.

r0 = 0 												
rInterrupt = 1 										; interrupt address (R1)
rRStack = 2 										; return stack (R2)
rDStack = 3 										; data stack (R3)
rProgram = 4 										; program code pointer (R4)
rVariables = 5 										; points to variables (R5)

rc = 12
rd = 13
re = 14
rf = 15

lri 	macro r,n 									; macro to load register.
		ldi (n) & 255
		plo r
		ldi (n) / 256
		phi r
		endm

videoMemory = 0700h 								; 64 x 32 Video RAM.
													; return stack R2 works down from this.

		br 		Boot 								; <<;>> skip over machine code. Also defines return (;) as $00

; *********************************************************************************************************************
;
;											Forth 1801 assembler primitives
;
;	@,!,+!,1+,1-,2*,2/,+,-,and,or,xor,literal,drop,dup,over,0-,0=,0<,0,1,-1,swap
; *********************************************************************************************************************

FW_Read:	 										; <<@>> read from variable page.
		ldx 										; read address 
		plo 	rVariables 							; point RVariables to it
		lda 	rVariables 							; read rVariables
		dec 	rVariables 							; unpick if overflowed.
		br 		_SaveD 								; and write it out.

; *********************************************************************************************************************

FW_Store:											; <<!>> write to variable page.
		lda 	rDStack								; read address
		plo 	rVariables 							; rVariables points to it
		lda 	rDStack 							; read data
		str 	rVariables 							; write it.
		sep 	rc

; *********************************************************************************************************************

FW_AddStore:										; <<+!>> add tos to memory
		lda 	rDStack								; read address
		plo 	rVariables 							; rVariables points to it
		lda 	rDStack 							; read data
		sex 	rVariables
		add 										; add to memory
		sex 	rDStack
		str 	rVariables 							; write it.
		sep 	rc

; *********************************************************************************************************************

FW_Inc:												; <<1+>> Increment
		ldi 	1
		br 		__AddWr

; *********************************************************************************************************************

FW_Dec:												; <<1->> Increment
		ldi 	0FFh
		br 		__AddWr

; *********************************************************************************************************************

FW_ShiftR:											; <<2/>> Shift right
		ldx  										; read it
		shr 										; shift right
		br 		_SaveD 								; write back.

; *********************************************************************************************************************

FW_ShiftL:											; <<2*>> Shift left
		ldx 										; read tos
		br 		__AddWr 							; add it to itself.

; *********************************************************************************************************************

FW_Add:												; <<+>> add top of stack values.
		lda 	rDStack 							; read TOS
__AddWr:add
		br 		_SaveD

; *********************************************************************************************************************

FW_Sub:												; <<->> sub top of stack values.
		lda 	rDStack 							; read TOS
		sd
		br 		_SaveD

; *********************************************************************************************************************

FW_And:												; <<and>> and top of stack values.
		lda 	rDStack 							; read TOS
		and
		br 		_SaveD

; *********************************************************************************************************************

FW_Or:												; <<or>> or top of stack values.
		lda 	rDStack 							; read TOS
		or
		br 		_SaveD

; *********************************************************************************************************************

FW_Xor:												; <<xor>> xor top of stack values.
		lda 	rDStack 							; read TOS
		xor
		br 		_SaveD

; *********************************************************************************************************************

FW_Literal:											; <<LITERAL>>, code loads literal to TOS
		lda 	rProgram 							; read the literal in
		br 		_PushD 								; push on stack

; *********************************************************************************************************************

FW_Drop:											; <<DROP>>, drops top of stack.
		lda 	rDStack 							
		sep 	rc

; *********************************************************************************************************************

FW_Dup:												; <<DUP>>, duplicate top of stack
		ldx 										; read top of stack.
		br 		_PushD

; *********************************************************************************************************************

FW_Over:inc 	rDStack 							; point to 2nd value
		ldx 										; read value
		dec 	rDStack 							; unpick increment
		br 		_PushD

; *********************************************************************************************************************

FW_Negate: 											; <<0->>Word, negates top of stack
		lda 	rDStack
		dec 	rDStack
		sdi 	0
		br 		_SaveD

; *********************************************************************************************************************

FW_EqualZero:										; <<0=>> Word, sets to 1 if TOS zero 0 otherwise.
		lda 	rDStack 							; get TOS
		bz 		FW_1 								; if zero, push 1 else push 0 (fall through)

; *********************************************************************************************************************

FW_0:	
		ghi 	rf 									; <<0>> Word, pushes 0 on stack.
		br 		_PushD

; *********************************************************************************************************************

FW_LessZero:										; <<0<>> Word, push 1 if negative else push 0
		lda 	rDStack 							; get TOS
		ani 	080h								; look at the sign bit.
		bz 		FW_0 								; if +ve push 0 else drop through and push 1.

; *********************************************************************************************************************

FW_1:	
		ldi 	1 									; <<1>> Word, pushes 1 on stack

_PushD:	dec 	rDStack 							; push on stack.
_SaveD:	str 	rDStack
		sep 	rc

; *********************************************************************************************************************

FW_Minus1:	
		ldi 	0FFh								; <<-1>> Word, pushes -1 on stack.
		br 		_PushD

; *********************************************************************************************************************

FW_Swap:											; <<SWAP>> swap tos values.
		lda 	rDStack 							; read TOS, save in RE.0
		plo 	re
		ldx 										; read new TOS save in RE.1
		phi 	re
		glo 	re 									; get value that is written
		str 	rDStack
		ghi 	re 									; get value to push
		br 		_PushD

; *********************************************************************************************************************

FW_Stop:br 		FW_Stop								; <<STOP>> word

; *********************************************************************************************************************
;
;											Start up uForth interpreter
;
; *********************************************************************************************************************

		org 	0FEh
Boot:	ghi 	r0 									; reset R2, the return stack, R0.1 will be zero at $00FE.
		plo 	rRStack
		ldi 	videoMemory / 256
		phi 	rRStack											
		dec 	rRStack 							; start at byte below screen

		ghi 	rRStack 							; reset high pointer R3 (data stack) and R5 (variable pointer) 
		phi 	rDStack
		phi 	rVariables

		lri 	rf,ProgramCode 						; reset R4, the program pointer, to the start of the code
		lda 	rf 									; RF now points to the address of the start, read it into R4
		phi 	rProgram
		lda 	rf
		plo 	rProgram 						
		lda 	rf 									; read stack bottom
		plo 	rDStack

		lri 	rc,ExecuteCompiledWord 				; RC points to the code to execute the word at R4.
		lri 	rd,ExecuteDefinedWord 				; RD points to the code to execute a new definition.
		sex  	rDStack 							; R3 points to data stack.
		sep 	rc 									; and start.

; *************************************************************************************************************************
;
;	Execute the word at (R4). This is either a 1 byte call (00-F7) or a 2 byte call (F8-FF) nn
;	Runs in RC.
;
; *************************************************************************************************************************

ExecuteCompiledWord:
		lda 	rProgram 								; get the next instruction to execute.
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

ProgramCode:
		dw 		Start
		db 		0A0h
Start:	
		db 	FW_Literal,42,FW_Literal,33,FW_Swap
		db 	FW_Stop

