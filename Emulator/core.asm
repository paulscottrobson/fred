	
	cpu 	1802

r2 = 2 												; return stack (down, words) points to TOS.
r3 = 3 												; data stack (up, bytes) points to TOS.
r4 = 4 												; execute word at RF
r5 = 5 												; defines word as a code word
r6 = 6 												; return from code word
re = 14 											; run P for code
rf = 15 											; code pointer.

	idl

	ldi 	6 										; set up return stack.
	phi 	r2
	ldi 	0
	plo 	r2

	ldi 	5
	phi 	r3
	ldi 	0
	plo 	r3
	sex 	r3 										; if you change it change it back !

	ldi 	ExecuteAnyWord/256
	phi 	r4
	ldi 	ExecuteAnyWord&255
	plo 	r4

	ldi 	ExecuteCompiledWord/256
	phi 	r5
	ldi 	ExecuteCompiledWord&255
	plo 	r5

	ldi 	ReturnCompiledWord/256
	phi	 	r6
	ldi 	ReturnCompiledWord&255
	plo 	r6

	ldi 	CodeWord/256
	phi 	rf
	ldi 	CodeWord&255
	plo 	rf

	sep 	r4

CodeWord:
	db 		Definition,033h,0FFh

ClearD:
	db 		0F8h,00h,0D4h				; code word just clears D silly

ReturnCode:
	db 		0D6h 						; code word does return.

Definition:
	db 		0D5h,Constant,42,ReturnCode ; compiled word pushes 42 and calls the return function.

Constant:
	lda 	rf 							; get inline 8 bit constant
	inc 	r3 							; push on stack.
	str 	r3 
	sep 	r4

;
;			uForth 1801 Runtime
;
;
;			This runs in R4. On entry R2 is the return stack (going down)
;			R2 the data stack (going up)
;
;			RF points to the code to be executed.
;
ExecuteAnyWord:

	lda 	rf 										; get the first byte of the next command
	adi 	8 										; this produces an overflow for $F8...$FF which are long calls.
	bdf 	ECW_LongCall 

	smi 	8 										; fix back and put in RE
	plo 	re 										
	ldi 	0
	phi 	re
	sep 	re 										; and execute it.
	br 		ExecuteAnyWord 					; function is re-entrant.

ECW_LongCall:
	phi 	re 										; we added 8 , so $F8..$FF will be 0-7 which is address high
	lda 	rf 										; get address low
	plo 	re
	sep 	re 										; and execute it.
	br 		ExecuteAnyWord 					; function is re-entrant.

;
;	If the code that we have just executed is a compiled word, it will be begin with SEP R5. This will go here.
; 	so this runs in R5.
;

ExecuteCompiledWord:
	dec 	r2 										; push RF.1 on the return stack.
	ghi 	rf
	str 	r2
	dec 	r2
	glo 	rf
	str 	r2

	glo 	re 										; we called it with SEP RE, so RE will point to the word code.
	plo 	rf 										; so put that in RF.
	ghi 	re
	phi 	rf
	sep 	r4 										; and call "ExecuteAnyWord"
	br 		ExecuteCompiledWord

;
;	The return word comes here, which is in R6, and is called by the Return function.
;

ReturnCompiledWord:
	lda 	r2 										; unstack the return address.
	plo 	rf
	lda 	r2
	phi 	rf
	sep 	r4 										; and execute the next word
	br 		ReturnCompiledWord

;
;	So if we execute a word it can be either CODE or COMPILED. Code words are a sequence of
;	1801 assembler. COMPILED words are a sequence of 1 (00-F7) or 2 (F8-FF 00-FF) which refer
; 	to addresses 0000-00F7 and 0000-07FF respectively. The former should be exclusively 1801
;	assembler.
;	
;	Code
;	====
; 	RF points to code (say) LDI 0 for simplicity. The word will be F8 00 D4 and will be run in RE.
;	On exit RF if unmodified will point to the byte after D4.
;
;	Compiled
;	========
;	If it points to compiled code say 14, and 14 is D5 15 where 15 does the code D6 (SEP R6)
;	(this is the code for ';' in FORTH e.g. return). D5 means its a compiled definition.
;
;	ExecuteAnyWord runs first, with RF pointing to the byte '14'. It reads the byte 14, sets RE to 14
;	and executes the code there.
;
;	That code is D5, so it switches to ExecuteCompiledWord with RE pointing to the byte after '14'. RF 
; 	(now pointing to next byte) is pushed on the stack. The value of RE, pointing to the byte after 
;	the D5, is copied into RF, and ExecuteAnyWord is called via the SEP R4.
;
;	It consequentially executes D6 (when it executes the 15 as in the first example)
;
;	When this happens the original RF value + 1 (after the first fetch) is pulled off the stack and we can 
;	continue by re-enetering ExecuteAnyWord
;
