;
;	FEL-1 Disassembly
;
;	EF1 is 1 when a keypad byte is available. It is read from INP 0. There is a shift switch. 
;	I think this is set manually. (Implied). Horizontal resolution is set by a toggle switch.
;
; 	EF2 and EF3 are external tests. EF2 detects tape stop. EF4 In ? Error ?
;
;	Port 1 is a device selector. 1 Keypad, 2 TV, 3 Tape Device
; 	Port 2 for keypad it is set to 0/1 for TV to 0/3, for Tape $20 is read.
;	Port 3 is some flags bit 2 (4) is the audio/tape out and bit 0 (1) is run.
;	Port 4 is the external control register. 
; 	Port 6 is an extension port (in and out)
;
;	Clock Frequency can be derived from the tone code. In BJC notes 04 is 360us. This is 160 + 40 + 40 *4
;	cycles. Hence it is clocked at 1Mhz. All the products in the table (kc x us) come to 1000
;
0000	00					IDL
0001	F8 01 				LDI 1 													; Set interrupt, stack
0003	B1 					PHI R1
0004	B2					PHI R2
0005	B4					PHI R4
0006 	B8					PHI R8
0007	F8 19 				LDI L0119 & 255 										; R1 = $119 Interrupt routine
0009 	A1 					PLO R1
000A	F8 FF 				LDI 0FFh 												; R2 = $1FF Stack top
000C 	A2 					PLO R2
000D 	F8 3B 				LDI L013B & 255 
000F 	A4 					PLO R4 													; R4 = $13B Execute next instruction
0010 	F8 66 				LDI L0166 & 255 
0012 	A8 					PLO R8 													; R8 = $166 Call $1nn where nn is next byte
0013	90 					GHI R0 													
0014 	B5 					PLO R5
0015 	F8 04 				LDI L00B4 & 255 										; R5 = $0B4 "Macro PC"
0017 	A5 					PHI R5 
0018 	D4 					SEP R4													; go to "Util" in R4 
;
;	7xxx Instructions
;
0019 	D8 					SEP R8 													; Fetch A and B from memory
001A 	73 					DB L0273 & 255
001B 	E6 					SEX R6 													; X points to register X
001C 	45 					LDA R5 													; fetch low byte
001D 	A3 					PLO R3 													; go there.
;
; 	7x1E M(A)->Vx
;
001E 	4A 					LDA RA 													; read M(RA)
001F 	56 					STR R6 													; save in X
0020 	D4 					SEP R4 	
;
;	7x21 M(B)->Vx
;
0021 	4B 					LDA RB 													; read M(RB)
0022 	56 					STR R6 													; save in X
0023 	D4 					SEP R4 	
;
;	7x24 Vx->M(A)
;
0024 	46 					LDA R6 													; get Vx
0025 	5A 					STR RA 													; write to M(RA)
0026 	D4 					SEP R4 	
;
;	7x27 Vx->M(B)
;
0027 	46 					LDA R6 													; get Vx
0028 	5B 					STR RB 													; write to M(RB)
0029 	D4 					SEP R4 	
;
;	7x2A Vx -> A.0
;
002A 	F8 11 				LDI 011h 												; point R7 to RA.0
002C 	A7 		L002C:		PLO R7
002D 	46 					LDA R6 													; get Vx
002E 	5B 					STR R7 													; write it there.
002F 	D4 					SEP R4
; 
;	7x30 Vx -> A.1
;
0030 	F8 10 				LDI 010h 												; RA.1 address
0032 	30 2C 				BR  L002C
; 
;	7x30 Vx -> B.0
;
0034 	F8 13 				LDI 013h 												; RB.0 address
0036 	30 2C 				BR  L002C
;
; 	7x38 A.0 -> Vx
;
0038 	8A 					GLO RA 													; RA.0 value
0039 	56 					STR R6 													; put in X
003A 	D4 					SEP R4
;
;	7x3B A.1 -> Vx
;
003B 	9A 					GHI RA 													; RA.1 value
003C 	56 					STR R6 													; put in X
003D 	D4 					SEP R4
;
;	7x3E Shift X left 4
;
003E 	D8 					SEP R8 													; Do Vx << 4
003F 	4D 					DB  L024D & 255
0040 	D4 					SEP R4
;
;	7x41 Shift X Right 4
;
0041 	F0 					LDX 													; Read R(X)
0042 	F6 					SHR
0043 	F6 					SHR
0044 	F6 					SHR
0045 	F6 					SHR
0046 	56 					STR R6 													; write it back
0047 	F6 					SHR
;
;	7x4B Vx Delay (Tape On, Speaker off)
;
0048 	E3 					SEX R3 													; X = P = R3
0049 	46 					LDA R6 													; read R(X)
004A 	BF 					PHI RF 													; put in RF.0
004B 	63		L004B: 		OUT 3 													; tape on, speaker on.
004C 	03 					DB 03
004D 	2F 					DEC RF 													; dec counter
004E 	9F 					GHI RF 													; timed out
004F 	3A 4B 				BNZ L004B 												; keep going.
0051	D4 					SEP R4 	
;
;	7x52 Convert Vx to 3 digit decimal at A,A+1,A+2
;
0052	F0 					LDX 													; get R(X)
0053	BF 					PHI RF 													; save in RF.1
0054	14 					LDI 14h 												; point R7 to the 100,10,1
0056 	A7 					PLO R7
0057 	2A 					DEC RA 													; predec RA
0058 	1A 		L0058:		INC RA 													; A to next cell.
0059 	93 					GHI R3 													; D = 0
005A 	5A 					STR RA 													; clear counter
005B 	47 		L005B:		LDA R7 													; read divisor
005C 	27 					DEC R7 													; unpick it
005D 	F5 					SD 														; subtract from R(X) 
005E 	3B 68 				BNF L0068 												; if no borrow then division complete
0060	56 					STR R6 													; write it back to R(X)
0061 	4A 					LDA RA 													; read counter of divisions
0062 	2A 					DEC RA 													; undo inc
0063 	FC 01 				ADI 01 													; inc counter
0065 	5A					STR RA 													; write back
0066 	30 58 				BR  L005B 												; try to deduct it again. 				
0068 	47 					LDA R7 													; get R7 - divider just done and inc R7 to next
0069 	F6 					SHR 													; shift it right
006A	3B 58 				BNF L0058 												; until found the 1, i.e. have done 1
006C 	9F 					GHI RF 													; fix up R6 back
006D 	56 					STR R6
006E 	D4 					SEP R4
;
;	7F6F INC A. Must use 7F6F so R6 points to VF, the byte before A
;
006F	1A 					INC RA 													; increment RA
0070 	16 					INC R6 	 												; R6 now points to RA
0071 	9A 					GHI RA 													; write it back.
0072 	56 					STR R6
0073 	16 					INC R6
0074 	8A 					GLO RA
0075 	56 					STR R6
0076 	D4 					SEP R4
0077	00 					DB 00
;
;	Clear Screen Routine
;
0078	93 					GHI R3 													; RA = $800 (R3.1 = 0)
0079	AA 					PLO RA
007A 	F8 08 				LDI 8
007C 	BA 					PHI RA 
007D	2A 		L007D:		DEC RA 													; dec RA
007E 	93 					GHI R3													; D = 0
007F 	5A 					STR RA 													; clear screen space
0080 	8A 					GLO RA 													; check RA.0
0081 	3A 7D 				BNZ L007D 												; go back if not finished
0083 	B4 					SEP R4 													; next instruction.

; 00B4 Boot FEL-1 Code

[TODO] 84-FF FEL-1 Code.

0100	00 00 00 00 		DB 0,0,0,0 												; V0-VF
0104	00 00 00 00 		DB 0,0,0,0
0108	00 00 00 00 		DB 0,0,0,0
010C	00 00 00 00 		DB 0,0,0,0
0110 	00 00 				DB 0,0 													; A
0112 	00 00 				DB 0,0 													; B

0114 	64 					DB 100 													; dividers.
0115 	0A 					DB 10
0116 	01 					DB 1
;
;	Interrupt Routine. Sets up R0 to point to display at $700 and decrements VD,VE,VF if non-zero.
;

0117 	42 		L0117:		LDA R2 													; pop D off the stack
0118 	70 					RET 													; return re-enabling interrupts.
0119 	22 		L0119: 		DEC R2 													; save T on Stack
011A 	78 					SAV		
011B 	22 					DEC R2 													; save D on Stack
011C 	52 					STR R2 													; Save on stack.

011D 	F8 07 				LDI 7  													; set R0 (display pointer) to $700	
011F 	B0 					PHI R0
0120	F8 00 				LDI 0
0122 	A0 					PLO R0

0123 	19 					INC R9 													; increment R9 (timer ?)

0124 	86 					GLO R6													; get R6 
0125 	BD 					PHI RD 													; save in RD.1

0126 	F8 0D 				LDI 0D 								
0128 	A6 					PLO R6
0129 	46 		L0129:		LDA R6 													; read R6 (VD Timer first time around)
012A 	26 					DEC R6 													; fix up R6
012B 	32 31 				BZ 	L0131
012D 	AD 					PLO RD  												; save in RD.0 								
012E 	2D 					DEC RD 													; decrement it (so we don't change DF)
012F 	8D 					GLO RD 													; recover it
0130 	56 					STR R6 													; save timer now updated
0131 	16 	    L0131:		INC R6 													; point to next timer
0132 	86 					GLO R6 													; get low byte
0133 	FB 10 				XRI 10h 												; done all timers
0135 	3A 29 				BNZ L0129 												; if not, go back round again.
0137 	9D 					GHI RD 													; get RD.1, fix R6 back up again.
0138 	A6 					PLO R6
0139 	30 17 				BR  L0117 												; and go back to exit the routine.

;
;	Main execution loop, run in R4. Sets up R6 (X) R7 (Y) and calls code from table at 01C0h
;

013B 	94 		L013B:		GHI R4 													; D = 1
013C 	B6 					PHI R6 													; Set R6,R7,RC High to Page 1.
013D 	B7 					PHI R7
013E 	BC 					PHI RC

013F	45 					LDA R5 													; Read R5 (instruction High)
0140 	AC 					PLO RC 													; Save in RC.0
0141 	FA 0F 				ANI 0Fh 												; get the X register number
0143 	A6 					PLO R6 													; R6 now points to Register X.

0144 	8C 					GLO RC 													; get the instruction High
0145 	F6 					SHR 													; shift right four times.
0146 	F6 					SHR
0147 	F6 					SHR
0148 	F6 					SHR 													; instruction code in D
0149 	32 60 				BZ  L0160 												; if zero, its a machine language
014B 	F9 C0 				ORI 0C0h 												; OR with $C0
014D 	AC 					PLO RC 													; Put in RC.0  now points to vector table

014E 	45 					LDA R5 													; Read low byte of instruction
014F 	25 					DEC R5 													; Point it back to R5
0150 	F6 					SHR 													; shift right four times
0151 	F6					SHR
0152 	F6					SHR
0153 	F6					SHR 													; D now contains the Y register number
0154 	A7 					PLO R7 													; R7 now points to Register Y.

0155 	4C 	 				LDA RC 													; Read High byte of program
0156 	B3 					PHI R3 													; save in R3.1
0157 	8C 					GLO RC 													; get low byte of RC 
0158 	FC 0F 				ADI 0Fh 												; point to low address (+1 already)
015A 	AC 					PLO RC 													; write it back
015B 	4C 					LDA RC 													; get low byte of address
015C 	A3 		L015C:		PLO R3 													; save in R3.0, now has code address
015D 	D3 					SEP R3 													; and call it
015E 	30 3B  				BR  L013B 												; make re-entrant
;
;	0aaa run machine code at aaa in P3.
;
0160 	86		L0160:		GHI R6 													; get R6.1 (1)
0161 	B3 					PHI R3 													; put in R3.1
0162 	45 					LDA R5 													; read instruction second byte.
0163 	30 5C 				BR L015C
;
;	R8 points here. Calls the $02 <next byte> running in RC.
;
0165 	DC 		L0165:		SEP RC 													; return.
0166	43 		L0166:		LDA R3 													; read next byte in code
0167 	AC 					PLO RC 													; save in RC.0
0168 	F8 02 				LDI $02 												; put 2xx in RC
016A 	BC 					PHI RC 													
016B 	30 65	L0165: 		BR 	L0165 												; and call it, making it re-entrant
;
;	R8 routines to return RF.1, RF.0.
;
016D	DC 		L016D:		SEP RC 													; get RF.1
016E 	9F 		L016E:		GHI RF
016F 	30 6D 				BR 	L016D
;
0171	DC 		L0171:		SEP RC 													; get RF.0
0172 	8F 		L0172:		GLO RF 													
0173 	30 6D 				BR 	L0171

;
;	Exaa - execute code at 01aa with X = 6
;
0175 	D8 		L0175:		SEP R8 													; load A and B into RA and RB
0176 	73 					DB  L0273 & 255
0177 	E6 					SEX R6 													; index is Vx
0178 	45 					LDA R5 													; get the 2nd instruction byte
0179 	A3 					PLO R3 													; and go there, jump indirect.
;
;	Ex7A . Hex keypad on, wait for byte
;
017A 	D8 					SEP R8 													; call hex keypad on at $0246
017B 	46 					DB L0246 												
017C 	3C 7C 	L017C:		BN1 L017C 												; wait for EF1 (byte ready)
017E 	68 		L017E:		INP 0 													; read to M(X)
017F 	D4 					SEP R4 
;
;	Ex80 . Hex keypad on, byte ready input else skip
;
0180 	D8 					SEP R8 													; call hex keypad on at $0246
0181 	46 					DB L0246 												
0182 	34 7E 				B1 L017E 												; if byte ready get it.
0184	15 		L0184:		INC R5 													; skip instruction
0185 	15 		L0185:		INC R5
0186 	D4 					SEP R4
;
;	Ex87 - EF2 Skip
;
0187 	35 84 				B2 L0184 												; skip if  EF2
0189 	D4 					SEP R4
;
;	Ex8A - EF3 Skip
;
018A 	36 84 				B3 L0184 												; skip if EF3
018C 	D4 					SEP R4
;
;	Ex8D - Ext Bus to Vx
;
018D 	6E 					INP 6 													; read port 6 input.
018E 	D4 					SEP R4
;
;	Ex8F - Vx to Ext Bus
;
018F 	66 					OUT 6 													; out to port 6
0190 	D4 					SEP R4
;
;	Ex91 - Write Vx to External Control Register
;
0191 	64 					OUT 4 													; external control register
0192 	D4 					SEP R4
;
;	E093 - Read tape -> M(A) concurrent using DMA Off. Need to turn TV off and Start tape before. 
;	to check tape end read check EF2.
;
0193	9A 					GHI RA 													; put RA in R0
0194 	B0 					PHI R0
0195	8A 					GLO RA
0196 	A0 					PLO R0
0197 	E3 					SEX R3 													; X = P = 3
0198 	61 					OUT 1 													; select tape
0199 	03 					DB 03
019A 	62 					OUT 2 													; tape read
019B  	20 					SEP R4
;
;	E3A0 - Write tape from M(A) to M(06FF). Need to turn TV off and start tape before.
;
01A0 	86 					GLO R6 													; read 3  (why E3A0)
01A1 	BE 					PHI RE
01A2 	93 		L01A2:		GHI R3 													; get R3.1 which is 1 (we are in R3)
01A3 	F6 					SHR 													; set DF = 1 D = 0. DF set for writing start
01A4 	AB  				PLO RB 													; save in RB.0 (parity)
01A5 	F8 08 				LDI 8 													; bits to do.
01A7 	AE 					PLO RE 													; save in RE.0
01A8 	4A 					LDA RA 													; read next byte
01A9 	BB 					PHI RB 													; save in RB.0
01AA 	D8 					SEP R8 													; write start bit
01AB 	85  				DB  L0285 												
01AC 	9B 		L01AC:		GHI RB 													; get the byte value
01AD 	F6 					SHR 													; put LSB in DF
01AE 	BB 					PLO RB 													; write it back
01AF 	DC 					SEP RC 													; write out DF 0/1.
01B0 	2E 					DEC RE 													; decrement bit counter
01B1 	8E 					GLO RE 													; if non zero go back and do next bit.
01B2 	3A AC 				BNZ L01AC 
01B4 	8B 					GLO RB 													; get the parity count
01B5 	F6 					SHR 													; shift into DF
01B6 	DC 					SEP RC 													; write that parity bit out
01B7 	8A 					GLO RA 													; check done whole page
01B8 	3A A2 				BNZ L01A2 												; if not keep going
01BA 	9A 					GHI RA 													; done to $0700 ($06FF last)
01BB 	FB 07 				XRI 7 													; (700 is video ram)
01BD 	3A A2 				BNZ L01A2 												; if not keep going
01BF 	D4 					SEP R4

;
;	Instruction vector tables
;
01C0 	00 		L01C0:		DB  0 													; 0xxx not decoded here
01C1 	02 					DB 	L020D & 255 										; 1mmm Do program at mmm (subroutine call)
01C2 	02					DB  L02B1 & 255 										; 2xkk Load kk into Vx
01C3 	02					DB  L0223 & 255											; 3xkk Skip if Vx != kk
01C4 	02					DB  L02CA & 255 										; 4xkk Vx = Random Number & kk
01C5 	02					DB  L021A & 255 										; 5xkk Vx = Vx + kk,skip if vx = 0
01C6 	02					DB  L025B & 255											; 6xxx Assorted
01C7 	00 					DB  L0019 & 255 										; 7xnn Assorted
01C8 	02					DB  L0299 & 255											; 8xyf Arithmetic
01C9 	02					DB  L02DD & 255 										; 9xys Display pattern
01CA 	02					DB  L0200 & 255 										; Ammm Load A immediate
01CB 	02					DB  L0209 & 255 										; Bmmm Load B immediate
01CC 	02					DB  L022B & 255 										; Cxy0 Skip if vx != vy
01CD 	02					DB  L02BE & 255											; Dxy0 Vx Tone, Vy Delay (Tape on spk off)
01CE 	01					DB  L0175 & 255 										; Exxx Assorted
01CF 	02					DB  L0215 & 255 										; Fmmm Jump to mmm

01D0 	00 					DB  0 													; 0aaa is not dispatched this way.

01D1 	0D 					DB 	L020D / 256 										; instruction tables (low address)
01D2 	B1					DB  L02B1 / 256
01D3 	23					DB  L0223 / 256
01D4 	CA					DB  L02CA / 256
01D5 	1A					DB  L021A / 256
01D6 	5B					DB  L025B / 256
01D7 	19 					DB  L0019 / 256
01D8 	99					DB  L0299 / 256
01D9 	DD					DB  L02DD / 256
01DA 	00					DB  L0200 / 256
01DB 	09					DB  L0209 / 256
01DC 	2B					DB  L022B / 256
01DD 	BE					DB  L02BE / 256
01DE 	75					DB  L0175 / 256
01DF 	15					DB  L0215 / 256

01E0 	00 00 00 00 		DB 	0,0,0,0 											; stack space
01E4 	00 00 00 00 		DB 	0,0,0,0
01E8 	00 00 00 00 		DB 	0,0,0,0
01EC 	00 00 00 00 		DB 	0,0,0,0
01F0 	00 00 00 00 		DB 	0,0,0,0
01F4 	00 00 00 00 		DB 	0,0,0,0
01F8 	00 00 00 00 		DB 	0,0,0,0
01FC 	00 00 00 00 		DB 	0,0,0,0
;
;	Ammm 	Load A with mmm
;
0200	F8 10 	L0200:		LDI 10h 												; point R7 to A
0202	A7 		L0202:		PLO R7
0203 	86 					GLO R6 													; get X address $10X so its $0X
0204 	57 					STR R7 													; write to A high and point to low
0205 	17 					INC R7
0206 	45 					LDA R5 													; get second byte of instruction
0207 	57 					STR R7 													; write to low byte
0208 	D4 					SEP R4
;
;	Bmmm 	Load B with mmm
;
0209	F8 12 	L0209:		LDI 12h													; point R7 to B and reuse code above
020B 	30 02				BR  L0202
;
;	1mmm	Do Program (Subroutine) at mmmm
;
020D 	15 		L020D:		INC R5 													; r5 point sto next instruction
020E 	85 					GLO R5 													; get return address low
020F 	22 					DEC R2 													; push on stack
0210	52 					STR R2
0211	95 					GHI R5 													; get return address high
0212 	22 					DEC R2 													; push on stack
0213 	52 
0214 	25 					DEC R5 													; point R5 to low byte and fall through.
;
;	Fmmm	Go to program at mmmm
;
0215	45 		L0215:		LDA R5 													; get low byte
0216 	A5 					PLO R5 													; put in FEL PC Low
0217 	86 					GLO R6 													; get X address $10X so this is $0X
0218 	B5 					PHI R5 													; put in FEL PC hight
0219 	D4 					SEP R4
;
;	3xkk 	Skip instruction if vx != kk
;
0223 	45 		L0223:		LDA R5 													; get kk value
0224 	E6 		L0224:		SEX R6 													; R[X] points to Vx
0225 	F3 					XOR 													; compare the values
0226 	32 2A 				BZ L022A 												; exit if same
0228 	15 					INC R5 													; skip
0229 	15 					INC R5
022A 	D4 		L022A:		SEP R4
;
;	Cxy0 	Skip if vx != vy
;
022B 	15 		L022B: 		INC R5 													; ignore second byte
022C 	47 					LDA R7 													; read Vy
022D 	30 24 				BR  L0224 												; so now its same as 3xkk
;
;	Copy Registers onto Stack
;
022F 	F8 00				LDI 0 													; point R6 to $100
0231 	A6					PLO R6
0232 	96 					GHI R6 													; set R7 to $1E0 stack space bottom.
0233 	B7 					PHI R7
0234 	F8 E0 				LDI 0E0h
0236 	A7 					PLO R7
0237 	46 		L0237:		LDA R6 													; read variable data
0238 	57 					STR R7 													; copy it out.
0239 	17 					INC R7 													; next byte
023A 	87 					GLO R7
023B 	FB F4 				XRI 0F4h 												; copied all 20 bytes of data ?
023D 	3A 37 				BNZ L0237
023F 	D4 					SEP R4
;
;	Turn the television off.
;
0240 	E3 					SEX R3 													; X = 3 (same as P)
0241 	61 					OUT 1  													; select TV device (2)
0242 	02 					DB  2 												
0243 	61 					OUT 2 													; turn it off
0244 	00 					DB 	0
0245 	D4 					SEP R4 													
;
;	Turn hex keypad on (probably run in RC)
;
0246 	EC 					SEX RC 													; X = C
0247 	61  				OUT 1 													; select Keypad device (1)
0248 	01 					DB 1 													
0249 	62					OUT 2 													; turn it on.
024A 	01 					DB 1
024B 	E6 					SEX R6 													; set X back and return.
024C 	D3 					SEP R3 
;
;	Shift Vx left 4
;
024D 	E6 					SEX R6 													; R(X) now points to Vx
024E 	F0 					LDX 													; get Vx
024F 	F4 					ADD 													; add it
0250 	56 					STR R6 													; write back << 1
0251 	F4 					ADD 													; add it
0252 	56 					STR R6 													; write back << 2
0253 	F4 					ADD 													; add it
0254 	56 					STR R6 													; write back << 3
0255 	F4 					ADD 													; add it, now << 4
0256 	56 					STR R6 													; write back to Vx
0257 	D3 					SEP R3 												
;
;	Tape Controller - code to write in low part of instruction
;
0258 	E5 					SEX R5 													; use R5 as X
0259 	63 					OUT 3 													; write low byte of instruction to port 3
025A 	D4 					SEP R4 													; return
025B 	00 					DB 0 													; unused
;
;	Turn the television on 
;
025C 	F8 00 				LDI 0 													; set display address to $700
025E 	A0 					PLO R0
025F 	F8 07 				LDI 7
0261 	B0  				PHI R0
0262 	E3 					SEX R3 													; X = 3 (same as P)
0263 	61 					OUT 1 													; select TV device (2)
0264 	02 					DB 2
0265 	62 					OUT 2													; turn TV on (why 3 ?)
0266 	03					DB 3 													
0267 	D4 					SEP R4 													
;
;	Turn hex keypad off
;
0268 	E3 					SEX R3 													; X = 3 (Same as P)
0269 	61 					OUT 1 													; select keypad device (1)
026A 	01					DB 1
026B 	62  			 	OUT 2													; and turn it off
026C 	00 					DB 0 
026D 	D4 					SEP R4
;
;	Return from subroutine
;
026E 	42 					LDA R2 													; pop high return 
026F 	B5 					PHI R5 													; into R5
0270 	42 					LDA R2 		 											; same with low
0271 	A5 					PLO R5
0272 	D4 					SEP R5 													; return.
;
;	Load A and B into RA and RB
;
0273	96 		L0273:		GHI R6 													; RF = $110
0274 	BF 					PHI RF
0275 	F8 10 				LDI 10h 
0277 	AF 					PLO RF
0278 	4F 					LDA RF 													; load in A
0279 	BA 					PHI RA
027A	4F 					LDA RF
027B 	AA 					PLO RA
027C 	4F 					LDA RF 													; load in B
027D 	BB 					PHI RB
027E 	4F 					LDA RF
027F 	AB 					PLO RB
0280 	D4 					SEP R3
;
;	2xkk write kk to vX
;
0281 	45 		L0281:		LDA R5 													; read 2nd instruction byte
0282 	56 					STR R6 													; save in Vx
0283 	D4 					SEP R4
;
;	Write to tape - delay
;
0284 	D3 		L0284:		SEP R3
0285	F8 14 				LDI 14h 												; set timer counter
0287 	AF   				PLO RF 
0288 	2F 		L0288:		DEC RF
0289 	8F 					GLO RF
028A 	3A 88 				BNZ L0288
028C  	30 B0 				BR 	L02B0 												; next time, it will write 0/1

;
;	Do tone Vx = Tone VY = Delay
;
028E 	46 		L028E:		LDA R6													; read X (tone)
028F 	BE 					PHI RE 													; store in tone register 
0290 	F8 6E 				LDI L016E & 255 										; set to identify return.
0292 	A6 					PLO R6 	
0293 	47 					LDA R7 													; read delay time.
0294 	BF 					PHI RF 													; set RF counter.
0295 	D8 					SEP R8 													; call the tone routine.
0296 	BA 					DB L02BA & 255
0297 	15 					INC R5 													; fetch the 2nd byte
0298 	D4 					SEP R4
;
;	8xyn 	x = x or y (1) x and y (2) x+y(4) x-y (5), V0 is carry / not borrow
;
0299 	22 		L0299:		DEC R2 													; push $D3 on the stack
029A 	F8 D3 				LDI 0D3h												; (SEP R3)
029C 	52 					STR R2
029D 	22 					DEC R2
029E 	45 					LDA R5 													; get the low byte
029F 	F9 F0 				ORI 0F0h 												; F1 F2 F4 F5 which are or and + -
02A1 	52 					STR R2 													; save on stack
02A2 	E6 					SEX R6 													; RX points to the Rx value
02A3 	47 					LDA R7 													; get the RY value
02A4 	D2 					SEP R2 													; call the code pushed on the stack
02A5 	56 					STR R6 													; save at R6 (Vx)
02A6 	F8 00 				LDI 0 													; set R6 to point to $100 V0
02A8 	A6 					PLO R6
02A9 	96 					GHI R6 													; D = 1
02AA 	33 					BDF L02AD 												; if DF clear then
02AC 	F6 					SHR 													; D = 0
02AD 	56 		L02AD:		STR R6 													; write DF out to V0 	
02AE 	D4 					SEP R4
;
;	Write DF to tape. Sets up R6 to return to tape code, and writes for 2 or 3 cycles depending on DF.
;
02AF 	D3 		L02AF:		SEP R3
02B0 	F8 72 	L02B0:		LDI L0172 & 255
02B2 	A6 					PLO R6	
02B3 	9C 					GHI RC 													; D = 2 (write cycles)
02B4 	3D B9  				BNF L02B9 												; if bit to write zero, skip
02B6 	1B 					INC RB 													; inc parity value in RB.0
02B7 	FC 03 				ORI 3 													; D = 3 
02B9 	AF 		L02B9:		PLO RF 													; put write value in RF
;
;	Tone Generate (P = C), RE.1 = Pitch, RF.0 = Cycles to do it for.
;	R6 is set to 72 for read tape and 6E for make tone, which is how it figures out what to do afterwards
;	this is used for tape and cassette out.
;
02BA 	EC  	L02BA:		SEX RC 													; X = P = C
02BB  	63 					OUT 3 													; set External Function Register -> Run
02BC 	05 					DB 05 													; speaker line
02BD 	9E 					GHI RE  												; value 3, set in write tape routine for tape
02BE 	FF 01 	L02BE:		SMI 1 													; short delay loop
02C0 	3A BE 				BNZ L02BE
02C2 	63					OUT 3 													; reset speaker line.
02C3 	01 					DB  01
02C4 	2F 					DEC RF 													; done it correct number of times
02C5 	D6 					SEP R6  												; call F0/F1 -> D, identify caller
02C6 	3A BA 				BNZ L02BA 												; tone, go back to tone loop
02C8 	30 B4 				BR  L0284												; tape, go back to tape loop
;
;	4xkk 	Vx = kk & random
;
02CA 	19 					INC R9 													; bump and read random lower
02CB 	89	 				GLO R9
02CC 	A7 					PLO R7 													; R7 = $01<R9.0>
02CD 	E7 					SEX R7 													; X points there, use as randomish data
02CE 	99 					GHI R9 													; random high
02CF 	F4 					ADD 													; R9.1 + Mem[$01<R9.0>]
02D0 	22 					DEC R2 													; push on stack
02D1 	52 					STR R2
02D2 	F6 					SHR 													; add to self shifted right
02D3 	E2 					SEX R2
02D4 	F4 					ADD
02D5 	B9 					PHI R9 													; update R9 high
02D6 	56 		 			STR R6 													; save at Vx
02D7 	E6 					SEX R6 													; RX points to Vx
02D8 	45 					LDA R5 													; read low byte (mask)
02D9 	F2 					AND 													; and with Vx
02DA 	56 					STR R6 													; update
02DB 	12 					INC R2 													; fix up stack and exit.
02DC 	D4 					SEP R4
;
;	9xys 	Draw sxs pattern (5 or 8) x = pattern address in page 3 y = tv cell address. 
;
02DD 	45 		L02DD:		LDA R5 													; Get next byte
02DE 	FA 0F 				ANI 0Fh 												; look at lower 4 bits which are size
02E0 	AF 					PLO RF 													; RF.0 is the number of lines to do. 
;
;	RF = #lines
;
02E1 	E6 		L02E1:		SEX R6 													; R(x) points to VX
02E2 	F0 					LDX 													; read X
02E3 	AA 					PLO RA 													; save in RA.0
02E4 	F8 03 				LDI 3 													; RA is $03[Vx]
02E6 	BA 					PHI RA
;
;	RF = #lines. RA = address of graphic data. Calculate cell address from tv cell address. 
;	Bits 3,4 are the vertical cell position (0-3, 8 pixels high cell). 
;	Bits 0,1,2 are the horizontal position. (0-7, 8 pixels wide cell).
;
02E7 	47 					LDA R7 													; read Y (Cell number)
02E8 	AB 					PLO RB 													; RB.0 = Y
02E9 	F6 					SHR 													; R6 = Y >> 1 << 4 (Y * 8)
02EA 	56 					STR R6   												; using shift left function, so bits
02EB 	D8 					SEP R8 													; 3 and 4 are now in bits 6,7
02EC 	4D 					DB  L024D & 255
02ED 	8B 					GLO RB 													; get original cell number for bits 0-2
02EE 	F1 					OR 														; or with bits 6-7
02EF 	FA C7  				ANI 0C7h 												; remove so only bits 0-2 and bits 6-7
02F1 	AB 					PLO RB
02F2 	F8 07 				LDI 07 													; set RB.1 = 07<addr>
02F4 	BB 					PHI RB

02F5 	4A 		L02F5: 		LDA RA 													; read first byte of data
02F6 	5B 					STR RB 													; write to the screen
02F7 	8B 					GLO RB 													; get low byte of screen address
02F8 	FC 08 				ADI 08 													; go one row down
02FA 	AB 					PLO RB 													; update screen address
02FB 	2F 					DEC RF 													; decrement line counter.
02FC 	8F 					GLO RF 													; check it
02FD 	3A F5 				BNZ L02F5 												; do next row.
02FF 	D4 					SEP R4
