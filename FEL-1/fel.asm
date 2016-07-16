;****************************************************************************************************************
;****************************************************************************************************************
;                                                        
;                                                FEL-1 Disassembly
;                                                =================
;                                                        
;          Original version by RCA 1974. Recommented and converted by Paul Robson (paul@robsons.org.uk)
;                                                        
;       Source provided courtesy of the Hagley Museum and Library from documents on "FRED" developments at
;     RCA, dated 1974-75; "Fred Folder 1", Acc. 2464, Box 919 described as the "Billie Joe Call" Collection,
;                      accession no. 2464.54.  Hagley Museum & Library, Wilmington, DE 19807
;                                                        
;           Many thanks to their Librarians, especially Lucas Clawson, for reproducing these documents
;                                 for the 1802 (and related) Processor community.
;                                                        
;             The original author is not currently known but may well have been Joseph A. Weisbecker.
;                                                        
;                       The source format is for Alfred Arnolds open source "AS" assembler.
;                                                        
;****************************************************************************************************************
;                                                        
;        These hardware notes should not be viewed as definitive, this information is derived from reading
;                        the above code. A more detailed document is under consideration.
;                                                        
;            EF1 is 1 when a keypad byte is available. It is read from INP 0. There is a shift switch.
;          I think this is set manually. (Implied). Horizontal resolution is set by a toggle switch. The
;                            monitor code relies on this being in 'single byte' mode.
;                                                        
;                     EF2 and EF3 are external tests. EF2 detects tape stop. EF4 In ? Error ?
;                                                        
;                           Port 1 is a device selector. 1 Keypad, 2 TV, 3 Tape Device
;                     Port 2 for keypad it is set to 0/1 for TV to 0/3, for Tape $20 is read.
;                   Port 3 is some flags bit 2 (4) is the audio/tape out and bit 0 (1) is run.
;                                    Port 4 is the external control register.
;                                    Port 6 is an extension port (in and out)
;                                                        
;      Clock Frequency can be derived from the tone code. In BJC notes 04 is 360us. This is 160 + 40 + 40 *4
;            cycles. Hence it is clocked at 1Mhz. All the products in the table (kc x us) come to 1000
;                                                        
;****************************************************************************************************************
;****************************************************************************************************************

           include felinclude.inc

start:
        idl                                                              
        ldi     1                                                        ; Set interrupt, stack
        phi     r1                                                       ; they are all in Page 1
        phi     r2                                                       
        phi     r4                                                       
        phi     r8                                                       
        ldi     interrupt & 255                                          ; R1 = $119 Interrupt routine
        plo     r1                                                       
        ldi     stacktop & 255                                           ; R2 = $1FF Stack top
        plo     r2                                                       
        ldi     nextinstruction & 255                                    
        plo     r4                                                       ; R4 = $13B Execute next instruction
        ldi     call02 & 255                                             
        plo     r8                                                       ; R8 = $166 Call $1nn where nn is next byte
        ghi     r0                                                       
        phi     r5                                                       
        ldi     monitor & 255                                            ; R5 = $0B4 "Macro PC"
        plo     r5                                                       
        sep     r4                                                       ; go to "Util" in R4

;****************************************************************************************************************
;                                                        
;                                                7xxx Instructions
;                                                        
;****************************************************************************************************************

opcode7:
        sep     r8                                                       ; Fetch A and B from memory
        db      readabregs & 255                                         
        sex     r6                                                       ; X points to register X
        lda     r5                                                       ; fetch low byte
        plo     r3                                                       ; go there.
;   
;   7x1E M(A)->Vx
;   
        lda     ra                                                       ; read M(RA)
        str     r6                                                       ; save in X
        sep     r4                                                       
;   
;   7x21 M(B)->Vx
;   
        lda     rb                                                       ; read M(RB)
        str     r6                                                       ; save in X
        sep     r4                                                       
;   
;   7x24 Vx->M(A)
;   
        lda     r6                                                       ; get Vx
        str     ra                                                       ; write to M(RA)
        sep     r4                                                       
;   
;   7x27 Vx->M(B)
;   
        lda     r6                                                       ; get Vx
        str     rb                                                       ; write to M(RB)
        sep     r4                                                       
;   
;   7x2A Vx -> A.0
;   
        ldi     (areg+1) & 255                                           ; point R7 to RA.0
setaddrreg:
        plo     r7                                                       
        lda     r6                                                       ; get Vx
        str     r7                                                       ; write it there.
        sep     r4                                                       
;   
;   7x30 Vx -> A.1
;   
        ldi     areg & 255                                               ; RA.1 address
        br      setaddrreg                                               
;   
;   7x30 Vx -> B.0
;   
        ldi     (breg+1) & 255                                           ; RB.0 address
        br      setaddrreg                                               
;   
;   7x38 A.0 -> Vx
;   
        glo     ra                                                       ; RA.0 value
        str     r6                                                       ; put in X
        sep     r4                                                       
;   
;   7x3B A.1 -> Vx
;   
        ghi     ra                                                       ; RA.1 value
        str     r6                                                       ; put in X
        sep     r4                                                       
;   
;   7x3E Shift X left 4
;   
        sep     r8                                                       ; Do Vx << 4
        db      shiftvxleft4 & 255                                       
        sep     r4                                                       
;   
;   7x41 Shift X Right 4
;   
        ldx                                                              ; Read R(X)
        shr                                                              
        shr                                                              
        shr                                                              
        shr                                                              
        str     r6                                                       ; write it back
        shr                                                              
;   
;   7x4B Vx Delay (Tape On, Speaker off)
;   
        sex     r3                                                       ; X = P = R3
        lda     r6                                                       ; read R(X)
        phi     rf                                                       ; put in RF.0
tapedelayloop:
        out     controllatch                                             ; tape on, speaker off.
        db      cltapebit+clrunmode                                      
        dec     rf                                                       ; dec counter
        ghi     rf                                                       ; timed out
        bnz     tapedelayloop                                            ; keep going.
        sep     r4                                                       
;   
;   7x52 Convert Vx to 3 digit decimal at A,A+1,A+2
;   
        ldx                                                              ; get R(X)
        phi     rf                                                       ; save in RF.1
        ldi     dectable & 255                                           ; point R7 to the 100,10,1
        plo     r7                                                       
        dec     ra                                                       ; predec RA
nextdigit:
        inc     ra                                                       ; A to next cell.
        ghi     r3                                                       ; D = 0
        str     ra                                                       ; clear counter
subtractunit:
        lda     r7                                                       ; read divisor
        dec     r7                                                       ; unpick it
        sd                                                               ; subtract from R(X)
        bnf     borrowoccurred                                           ; if no borrow then division complete
        str     r6                                                       ; write it back to R(X)
        lda     ra                                                       ; read counter of divisions
        dec     ra                                                       ; undo inc
        adi     01                                                       ; inc counter
        str     ra                                                       ; write back
        br      subtractunit                                             ; try to deduct it again.
borrowoccurred:
        lda     r7                                                       ; get R7 - divider just done and inc R7 to next
        shr                                                              ; shift it right
        bnf     nextdigit                                                ; until found the 1, i.e. have done 1
        ghi     rf                                                       ; fix up R6 back
        str     r6                                                       
        sep     r4                                                       
;   
;   7F6F INC A. Must use 7F6F so R6 points to VF, the byte before A
;   
        inc     ra                                                       ; increment RA
        inc     r6                                                       ; R6 now points to RA
        ghi     ra                                                       ; write it back.
        str     r6                                                       
        inc     r6                                                       
        glo     ra                                                       
        str     r6                                                       
        sep     r4                                                       
        db      00                                                       

;****************************************************************************************************************
;                                                        
;                                              Clear Screen Routine
;                                                        
;****************************************************************************************************************

        ghi     r3                                                       ; RA = $800 (R3.1 = 0)
        plo     ra                                                       
        ldi     (screen / 256) + 1                                       
        phi     ra                                                       
clsloop:
        dec     ra                                                       ; dec RA
        ghi     r3                                                       ; D = 0
        str     ra                                                       ; clear screen space
        glo     ra                                                       ; check RA.0
        bnz     clsloop                                                  ; go back if not finished
        sep     r4                                                       ; next instruction.

;****************************************************************************************************************
;                                                        
;                                  This is the FEL-1 Boot Code / Micro monitor.
;                                                        
;****************************************************************************************************************

monitor:
        fel     06000h                                                   ; stop tape
        fel     0022fh                                                   ; copy registers to stack space.
;   
;   Read key 0 for Run, C for Write, A for Read Mem, B for Write Mem
;   
        fel     0e17ah                                                   ; read Byte into V1
        fel     03100h                                                   ; skip next instruction if not 00
        fel     0f400h                                                   ; if was 00, then run program from 400
        fel     0310ch                                                   ; if was 0C, then go to write code
        fel     0f000h+felwritetape                                      
;   
;   Read three keystrokes into A
;   
        fel     0025ch                                                   ; turn television on.
        fel     00078h                                                   ; clear screen memory
        fel     0e27ah                                                   ; read byte to V2 (high address nibble)
        fel     07230h                                                   ; write to MSB of A
        fel     0e27ah                                                   ; read byte to V2 (middle address nibble)
        fel     0e37ah                                                   ; read byte to V3 (low address nibble)
        fel     01000h+felpack                                           ; call pack V2/V3 to V2
        fel     0722ah                                                   ; write to LSB of A
        fel     02900h                                                   ; Clear V9
;   
;   Display Address
;   
feldisplay:
        fel     0723bh                                                   ; MSB of A to V2
        fel     02409h                                                   ; Set V4 = (1,1)
        fel     01000h+felshow                                           ; unpack and show V2
        fel     07238h                                                   ; LSB of A to V2
        fel     0240bh                                                   ; Set V4 = (3,1)
        fel     01000h+felshow                                           ; unpack and show V2
;   
;   Display Data
;   
        fel     0721eh                                                   ; read contents of Memory(A) to V2
        fel     02416h                                                   ; Set V4 = (6,2)
        fel     01000h+felshow                                           ; unpack and show V2
;   
;   First time around, increment A to point to next cell, second time around go back to the display address code.
;   
        fel     03901h                                                   ; increment A if V9 != 0 (not first time)
        fel     07f6fh                                                   
        fel     0e27ah                                                   ; get hex key (upper nibble)
        fel     02901h                                                   ; set V9 = 1 so increments next time
        fel     0310ah                                                   ; been round twice ?
        fel     0f000h+feldisplay                                        ; if command was A (read) do next w/o update
        fel     0e37ah                                                   ; get the low nibble
        fel     010e2h                                                   ; call pack V2/V3 to V2
        fel     07224h                                                   ; store V(2) at M->A (e.g. new address)
        fel     0f000h+feldisplay                                        ; redisplay address and data.
;   
;   Write code to tape
;   
felwritetape:
        fel     00268h                                                   ; disable hex keyboard input
        fel     021ffh                                                   ; set V1 = $FF (5 sec approx)
        fel     07148h                                                   ; delay of this length so stabilises
        fel     02140h                                                   ; set V1 = $40 (1 sec approx)
        fel     07148h                                                   ; more delay
        fel     0d210h                                                   ; tone and delay
        fel     07148h                                                   ; delay with that tone (start tone ?)
        fel     0a000h                                                   ; A = 0
        fel     0f000h+felnext                                           ; (patched out)
felnext:
        fel     0e3a0h                                                   ; write tape M(A) to end
        fel     0d210h                                                   ; tone and delay
felstop:
        fel     0f000h+felstop                                           ; stop
;   
;   Pack V2/V3 nibbles into a single byte (subroutine)
;   
felpack:
        fel     0723eh                                                   ; Shift V2 left 4 bits
        fel     08231h                                                   ; V2 = V2 or V3
        fel     0026eh                                                   ; return
;   
;   Unpack V2 into 2 digits and display at V4 (subroutine)
;   
felshow:
        fel     0b300h                                                   ; point B to $300
        fel     0230fh                                                   ; V3 = 0Fh
        fel     08322h                                                   ; And out lowest nibble into V3
        fel     07241h                                                   ; Shift V2 right 4, now has highest nibble
        fel     07334h                                                   ; B = $03<low>
        fel     07321h                                                   ; Read Mem(B) -> V3, addr of gfx data
        fel     09345h                                                   ; Draw V3 pattern at cell V4
        fel     054ffh                                                   ; point to previous cell
        fel     07234h                                                   ; B = $03<high>
        fel     07221h                                                   ; Read Mem(B) -> V2, addr of gfx data
        fel     09245h                                                   ; Draw V2 pattern at cell V4
        fel     0026eh                                                   ; return

;****************************************************************************************************************
;                                                        
;                                       Register Area and Conversion table
;                                                        
;****************************************************************************************************************

registers:
        db      0,0,0,0                                                  ; V0-VF
        db      0,0,0,0                                                  
        db      0,0,0,0                                                  
        db      0,0,0,0                                                  
areg:
        db      0,0                                                      ; A
breg:
        db      0,0                                                      ; B

dectable:
        db      100                                                      ; dividers.
        db      10                                                       
        db      1                                                        

;****************************************************************************************************************
;                                                        
;                                               Interrupt Routine.
;                   Sets up R0 to point to display at $700 and decrements VD,VE,VF if non-zero.
;                                                        
;****************************************************************************************************************

exitinterrupt:
        lda     r2                                                       ; pop D off the stack
        ret                                                              ; return re-enabling interrupts.
interrupt:
        dec     r2                                                       ; save T on Stack
        sav                                                              
        dec     r2                                                       ; save D on Stack
        str     r2                                                       ; Save on stack.

        ldi     screen/256                                               ; set R0 (display pointer) to $700
        phi     r0                                                       
        ldi     screen&255                                               
        plo     r0                                                       

        inc     r9                                                       ; increment R9 (timer ?)

        glo     r6                                                       ; get R6
        phi     rd                                                       ; save in RD.1

        ldi     (registers + 0dh) & 255                                  ; point to Vd
        plo     r6                                                       
timerupdateloop:
        lda     r6                                                       ; read R6 (VD Timer first time around)
        dec     r6                                                       ; fix up R6
        bz      nexttimer                                                
        plo     rd                                                       ; save in RD.0
        dec     rd                                                       ; decrement it (so we don't change DF)
        glo     rd                                                       ; recover it
        str     r6                                                       ; save timer now updated
nexttimer:
        inc     r6                                                       ; point to next timer
        glo     r6                                                       ; get low byte
        xri     (registers+10h) & 255                                    ; done all timers
        bnz     timerupdateloop                                          ; if not, go back round again.
        ghi     rd                                                       ; get RD.1, fix R6 back up again.
        plo     r6                                                       
        br      exitinterrupt                                            ; and go back to exit the routine.

;****************************************************************************************************************
;                                                        
;            Main execution loop, run in R4. Sets up R6 (X) R7 (Y) and calls code from table at 01C0h
;                                                        
;****************************************************************************************************************

nextinstruction:
        ghi     r4                                                       ; D = 1
        phi     r6                                                       ; Set R6,R7,RC High to Page 1.
        phi     r7                                                       
        phi     rc                                                       

        lda     r5                                                       ; Read R5 (instruction High)
        plo     rc                                                       ; Save in RC.0
        ani     0fh                                                      ; get the X register number
        plo     r6                                                       ; R6 now points to Register X.

        glo     rc                                                       ; get the instruction High
        shr                                                              ; shift right four times.
        shr                                                              
        shr                                                              
        shr                                                              ; instruction code in D
        bz      opcode0                                                  ; if zero, its a machine language
        ori     instructionvector & 255                                  ; OR with $C0
        plo     rc                                                       ; Put in RC.0  now points to vector table

        lda     r5                                                       ; Read low byte of instruction
        dec     r5                                                       ; Point it back to R5
        shr                                                              ; shift right four times
        shr                                                              
        shr                                                              
        shr                                                              ; D now contains the Y register number
        plo     r7                                                       ; R7 now points to Register Y.

        lda     rc                                                       ; Read High byte of program
        phi     r3                                                       ; save in R3.1
        glo     rc                                                       ; get low byte of RC
        adi     0fh                                                      ; point to low address (+1 already)
        plo     rc                                                       ; write it back
        lda     rc                                                       ; get low byte of address
execr3:
        plo     r3                                                       ; save in R3.0, now has code address
        sep     r3                                                       ; and call it
        br      nextinstruction                                          ; make re-entrant

;****************************************************************************************************************
;                                                        
;                                       0aaa run machine code at aaa in P3.
;                                                        
;****************************************************************************************************************

opcode0:
        glo     r6                                                       ; get R6.0 (Hi)
        phi     r3                                                       ; put in R3.1
        lda     r5                                                       ; read instruction second byte.
        br      execr3                                                   
;   
;   R8 points here. Calls the $02 <next byte> running in RC.
;   
exit02call:
        sep     rc                                                       ; return.
call02:
        lda     r3                                                       ; read next byte in code
        plo     rc                                                       ; save in RC.0
        ldi     02                                                       ; put 2xx in RC
        phi     rc                                                       
        br      exit02call                                               ; and call it, making it re-entrant
;   
;   R8 routines to return RF.1, RF.0.
;   
exitghirf:
        sep     rc                                                       ; get RF.1
ghirf:
        ghi     rf                                                       
        br      exitghirf                                                
;   
exitglorf:
        sep     rc                                                       ; get RF.0
glorf:
        glo     rf                                                       
        br      exitglorf                                                

;****************************************************************************************************************
;                                                        
;                                     Exaa - execute code at 01aa with X = 6
;                                                        
;****************************************************************************************************************

instructione:
        sep     r8                                                       ; load A and B into RA and RB
        db      readabregs & 255                                         
        sex     r6                                                       ; index is Vx
        lda     r5                                                       ; get the 2nd instruction byte
        plo     r3                                                       ; and go there, jump indirect.
;   
;   Ex7A . Hex keypad on, wait for byte
;   
        sep     r8                                                       ; call hex keypad on at $0246
        db      keypadon & 255                                           
waitkeypress:
        bn1     waitkeypress                                             ; wait for EF1 (byte ready)
readkeyinput:
        db      68h+keypadport                                           ; read to M(X) (AS Cannot assemble INP0)
        sep     r4                                                       
;   
;   Ex80 . Hex keypad on, byte ready input else skip
;   
        sep     r8                                                       ; call hex keypad on at $0246
        db      keypadon & 255                                           
        b1      readkeyinput                                             ; if byte ready get it.
skipinstruction:
        inc     r5                                                       ; skip instruction
        inc     r5                                                       
        sep     r4                                                       
;   
;   Ex87 - EF2 Skip
;   
        b2      skipinstruction                                          ; skip if  EF2
        sep     r4                                                       
;   
;   Ex8A - EF3 Skip
;   
        b3      skipinstruction                                          ; skip if EF3
        sep     r4                                                       
;   
;   Ex8D - Ext Bus to Vx
;   
        inp     externalbus                                              ; read port 6 input.
        sep     r4                                                       
;   
;   Ex8F - Vx to Ext Bus
;   
        out     externalbus                                              ; out to port 6
        sep     r4                                                       
;   
;   Ex91 - Write Vx to External Control Register
;   
        out     externalcontrol                                          ; external control register
        sep     r4                                                       
;   
;   E093 - Read tape -> M(A) concurrent using DMA Off. Need to turn TV off and Start tape before.
;   to check tape end read check EF2.
;   
        ghi     ra                                                       ; put RA in R0
        phi     r0                                                       
        glo     ra                                                       
        plo     r0                                                       
        sex     r3                                                       ; X = P = 3
        out     selectdevice                                             ; select tape
        db      devtape                                                  
        out     controldevice                                            ; tape read
        db      ctaperead                                                
        sep     r4                                                       
;   
;   R1(0)  -> Vx
;   
        ghi     r0                                                       
        str     r6                                                       
        sep     r4                                                       
;   
;   E3A0 - Write tape from M(A) to M(06FF). Need to turn TV off and start tape before.
;   
        glo     r6                                                       ; read 3  (why E3A0)
        phi     re                                                       
tapebyteoutloop:
        ghi     r3                                                       ; get R3.1 which is 1 (we are in R3)
        shr                                                              ; set DF = 1 D = 0. DF set for writing start
        plo     rb                                                       ; save in RB.0 (parity)
        ldi     8                                                        ; bits to do.
        plo     re                                                       ; save in RE.0
        lda     ra                                                       ; read next byte
        phi     rb                                                       ; save in RB.0
        sep     r8                                                       ; write start bit
        db      writetapedelay & 255                                     
tapebitoutloop:
        ghi     rb                                                       ; get the byte value
        shr                                                              ; put LSB in DF
        phi     rb                                                       ; write it back
        sep     rc                                                       ; write out DF 0/1.
        dec     re                                                       ; decrement bit counter
        glo     re                                                       ; if non zero go back and do next bit.
        bnz     tapebitoutloop                                           
        glo     rb                                                       ; get the parity count
        shr                                                              ; shift into DF
        sep     rc                                                       ; write that parity bit out
        glo     ra                                                       ; check done whole page
        bnz     tapebyteoutloop                                          ; if not keep going
        ghi     ra                                                       ; done to $0700 ($06FF last)
        xri     7                                                        ; (700 is video ram)
        bnz     tapebyteoutloop                                          ; if not keep going
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                                            Instruction vector tables
;                                                        
;****************************************************************************************************************

instructionvector:
        db      0                                                        ; 0xxx not decoded here
        db      opcode1 / 256                                            ; 1mmm Do program at mmm (subroutine call)
        db      opcode2 / 256                                            ; 2xkk Load kk into Vx
        db      opcode3 / 256                                            ; 3xkk Skip if Vx != kk
        db      opcode4 / 256                                            ; 4xkk Vx = Random Number & kk
        db      opcode5 / 256                                            ; 5xkk Vx = Vx + kk,skip if vx = 0
        db      opcode6 / 256                                            ; 6xxx Assorted
        db      opcode7 / 256                                            ; 7xnn Assorted
        db      opcode8 / 256                                            ; 8xyf Arithmetic
        db      opcode9 / 256                                            ; 9xys Display pattern
        db      instructiona / 256                                       ; Ammm Load A immediate
        db      instructionb / 256                                       ; Bmmm Load B immediate
        db      instructionc / 256                                       ; Cxy0 Skip if vx != vy
        db      instructiond / 256                                       ; Dxy0 Vx Tone, Vy Delay (Tape on spk off)
        db      instructione / 256                                       ; Exxx Assorted
        db      instructionf / 256                                       ; Fmmm Jump to mmm

        db      0                                                        ; 0aaa is not dispatched this way.

        db      opcode1 & 255                                            ; instruction tables (low address)
        db      opcode2 & 255                                            
        db      opcode3 & 255                                            
        db      opcode4 & 255                                            
        db      opcode5 & 255                                            
        db      opcode6 & 255                                            
        db      opcode7 & 255                                            
        db      opcode8 & 255                                            
        db      opcode9 & 255                                            
        db      instructiona & 255                                       
        db      instructionb & 255                                       
        db      instructionc & 255                                       
        db      instructiond & 255                                       
        db      instructione & 255                                       
        db      instructionf & 255                                       

stack:
        db      0,0,0,0                                                  ; stack space
        db      0,0,0,0                                                  
        db      0,0,0,0                                                  
        db      0,0,0,0                                                  
        db      0,0,0,0                                                  
        db      0,0,0,0                                                  
        db      0,0,0,0                                                  
        db      0,0,0                                                    
stacktop:
        db      0                                                        

;****************************************************************************************************************
;                                                        
;                                              Ammm  Load A with mmm
;                                                        
;****************************************************************************************************************

instructiona:
        ldi     areg & 255                                               ; point R7 to A
loadaddrconst:
        plo     r7                                                       
        glo     r6                                                       ; get X address $10X so its $0X
        str     r7                                                       ; write to A high and point to low
        inc     r7                                                       
        lda     r5                                                       ; get second byte of instruction
        str     r7                                                       ; write to low byte
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                                              Bmmm  Load B with mmm
;                                                        
;****************************************************************************************************************

instructionb:
        ldi     breg & 255                                               ; point R7 to B and reuse code above
        br      loadaddrconst                                            

;****************************************************************************************************************
;                                                        
;                                      1mmm Do Program (Subroutine) at mmmm
;                                                        
;****************************************************************************************************************

opcode1:
        inc     r5                                                       ; r5 point sto next instruction
        glo     r5                                                       ; get return address low
        dec     r2                                                       ; push on stack
        str     r2                                                       
        ghi     r5                                                       ; get return address high
        dec     r2                                                       ; push on stack
        str     r2                                                       
        dec     r5                                                       ; point R5 to low byte and fall through.

;****************************************************************************************************************
;                                                        
;                                           Fmmm Go to program at mmmm
;                                                        
;****************************************************************************************************************

instructionf:
        lda     r5                                                       ; get low byte
        plo     r5                                                       ; put in FEL PC Low
        glo     r6                                                       ; get X address $10X so this is $0X
        phi     r5                                                       ; put in FEL PC hight
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                                         5xkk add kk to vx, skip if zero
;                                                        
;****************************************************************************************************************

opcode5:
        sex     r6                                                       ; access VX
        lda     r5                                                       ; read 2nd byte
        add                                                              ; add to VX
        str     r6                                                       ; write back
        bz      skipinstruction2                                         ; if zero skip
        sep     r4                                                       
        inc     r5                                                       ; unused
        sep     r4                                                       ; unused

;****************************************************************************************************************
;                                                        
;                                       3xkk  Skip instruction if vx != kk
;                                                        
;****************************************************************************************************************

opcode3:
        lda     r5                                                       ; get kk value
skipifvxnotd:
        sex     r6                                                       ; R[X] points to Vx
        xor                                                              ; compare the values
        bz      dontskip                                                 ; exit if same
skipinstruction2:
        inc     r5                                                       ; skip
        inc     r5                                                       
dontskip:
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                                             Cxy0  Skip if vx != vy
;                                                        
;****************************************************************************************************************

instructionc:
        inc     r5                                                       ; ignore second byte
        lda     r7                                                       ; read Vy
        br      skipifvxnotd                                             ; so now its same as 3xkk

;****************************************************************************************************************
;                                                        
;                                            Copy Registers onto Stack
;                                                        
;****************************************************************************************************************

        ldi     0                                                        ; point R6 to $100
        plo     r6                                                       
        ghi     r6                                                       ; set R7 to $1E0 stack space bottom.
        phi     r7                                                       
        ldi     stack & 255                                              
        plo     r7                                                       
copyregloop:
        lda     r6                                                       ; read variable data
        str     r7                                                       ; copy it out.
        inc     r7                                                       ; next byte
        glo     r7                                                       
        xri     0f4h                                                     ; copied all 20 bytes of data ?
        bnz     copyregloop                                              
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                                            Turn the television off.
;                                                        
;****************************************************************************************************************

        sex     r3                                                       ; X = 3 (same as P)
        out     selectdevice                                             ; select TV device (2)
        db      devtv                                                    
        out     controldevice                                            ; turn it off
        db      ctvoff                                                   
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                                     Turn hex keypad on (probably run in RC)
;                                                        
;****************************************************************************************************************

keypadon:
        sex     rc                                                       ; X = C
        out     selectdevice                                             ; select Keypad device (1)
        db      devkeypad                                                
        out     controldevice                                            ; turn it on.
        db      ckeyon                                                   
        sex     r6                                                       ; set X back and return.
        sep     r3                                                       

;****************************************************************************************************************
;                                                        
;                                                 Shift Vx left 4
;                                                        
;****************************************************************************************************************

shiftvxleft4:
        sex     r6                                                       ; R(X) now points to Vx
        ldx                                                              ; get Vx
        add                                                              ; add it
        str     r6                                                       ; write back << 1
        add                                                              ; add it
        str     r6                                                       ; write back << 2
        add                                                              ; add it
        str     r6                                                       ; write back << 3
        add                                                              ; add it, now << 4
        str     r6                                                       ; write back to Vx
        sep     r3                                                       
;   
;   Tape Controller - code to write in low part of instruction
;   
opcode6:
        sex     r5                                                       ; use R5 as X
        out     controllatch                                             ; write low byte of instruction to port 3
        sep     r4                                                       ; return
        db      0                                                        ; unused

;****************************************************************************************************************
;                                                        
;                                             Turn the television on
;                                                        
;****************************************************************************************************************

        ldi     0                                                        ; set display address to $700
        plo     r0                                                       
        ldi     screen / 256                                             
        phi     r0                                                       
        sex     r3                                                       ; X = 3 (same as P)
        out     selectdevice                                             ; select TV device (2)
        db      devtv                                                    
        out     controldevice                                            ; turn TV on (why 3 ?)
        db      ctvon                                                    
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                                               Turn hex keypad off
;                                                        
;****************************************************************************************************************

        sex     r3                                                       ; X = 3 (Same as P)
        out     selectdevice                                             ; select keypad device (1)
        db      devkeypad                                                
        out     controldevice                                            ; and turn it off
        db      ckeyoff                                                  
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                                             Return from subroutine
;                                                        
;****************************************************************************************************************

        lda     r2                                                       ; pop high return
        phi     r5                                                       ; into R5
        lda     r2                                                       ; same with low
        plo     r5                                                       
        sep     r4                                                       ; return.
;   
;   Load A and B into RA and RB
;   
readabregs:
        ghi     r6                                                       ; RF = $110
        phi     rf                                                       
        ldi     areg & 255                                               
        plo     rf                                                       
        lda     rf                                                       ; load in A
        phi     ra                                                       
        lda     rf                                                       
        plo     ra                                                       
        lda     rf                                                       ; load in B
        phi     rb                                                       
        lda     rf                                                       
        plo     rb                                                       
        sep     r3                                                       

;****************************************************************************************************************
;                                                        
;                                               2xkk write kk to vX
;                                                        
;****************************************************************************************************************

opcode2:
        lda     r5                                                       ; read 2nd instruction byte
        str     r6                                                       ; save in Vx
        sep     r4                                                       
;   
;   Write to tape - delay
;   
exitwritetape:
        sep     r3                                                       
writetapedelay:
        ldi     14h                                                      ; set timer counter
        plo     rf                                                       
writetapedelayloop:
        dec     rf                                                       
        glo     rf                                                       
        bnz     writetapedelayloop                                       
        br      writedfbittape                                           ; next time, it will write 0/1

;   
;   Do tone Vx = Tone VY = Delay
;   
playtone:
        lda     r6                                                       ; read X (tone)
        phi     re                                                       ; store in tone register
        ldi     ghirf & 255                                              ; set to identify return.
        plo     r6                                                       
        lda     r7                                                       ; read delay time.
        phi     rf                                                       ; set RF counter.
        sep     r8                                                       ; call the tone routine.
        db      tonegeneration & 255                                     
        inc     r5                                                       ; fetch the 2nd byte
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                    8xyn  x = x or y (1) x and y (2) x+y(4) x-y (5), V0 is carry / not borrow
;                                                        
;****************************************************************************************************************

opcode8:
        dec     r2                                                       ; push $D3 on the stack
        ldi     0d3h                                                     ; (SEP R3)
        str     r2                                                       
        dec     r2                                                       
        lda     r5                                                       ; get the low byte
        ori     0f0h                                                     ; F1 F2 F4 F5 which are or and + -
        str     r2                                                       ; save on stack
        sex     r6                                                       ; RX points to the Rx value
        lda     r7                                                       ; get the RY value
        sep     r2                                                       ; call the code pushed on the stack
        str     r6                                                       ; save at R6 (Vx)
        ldi     0                                                        ; set R6 to point to $100 V0
        plo     r6                                                       
        ghi     r6                                                       ; D = 1
        bdf     writedf                                                  ; if DF clear then
        shr                                                              ; D = 0
writedf:
        str     r6                                                       ; write DF out to V0
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;       Write DF to tape. Sets up R6 to return to tape code, and writes for 2 or 3 cycles depending on DF.
;                                                        
;****************************************************************************************************************

exitwritebit:
        sep     r3                                                       
writedfbittape:
        ldi     glorf & 255                                              
        plo     r6                                                       
        ghi     rc                                                       ; D = 2 (write cycles)
        bnf     savecyclesize                                            ; if bit to write zero, skip
        inc     rb                                                       ; inc parity value in RB.0
        adi     3                                                        ; D = 5
savecyclesize:
        plo     rf                                                       ; put write value in RF

;****************************************************************************************************************
;                                                        
;                        Tone Generate (P = C), RE.1 = Pitch, RF.0 = Cycles to do it for.
;                   R6 is set to 72 for read tape and 6E for make tone, which is how it figures
;                        out what to do afterwards,this is used for tape and cassette out.
;                                                        
;****************************************************************************************************************

tonegeneration:
        sex     rc                                                       ; X = P = C
        out     controllatch                                             ; set External Function Register -> Run
        db      clspeakerbit+clrunmode                                   ; speaker line
        ghi     re                                                       ; value 3, set in write tape routine for tape
instructiond:
        smi     1                                                        ; short delay loop
        bnz     instructiond                                             
        out     controllatch                                             ; reset speaker line.
        db      clrunmode                                                
        dec     rf                                                       ; done it correct number of times
        sep     r6                                                       ; call F0/F1 -> D, identify caller
        bnz     tonegeneration                                           ; tone, go back to tone loop
        br      exitwritetape                                            ; tape, go back to tape loop

;****************************************************************************************************************
;                                                        
;                                             4xkk  Vx = kk & random
;                                                        
;****************************************************************************************************************

opcode4:
        inc     r9                                                       ; bump and read random lower
        glo     r9                                                       
        plo     r7                                                       ; R7 = $01<R9.0>
        sex     r7                                                       ; X points there, use as randomish data
        ghi     r9                                                       ; random high
        add                                                              ; R9.1 + Mem[$01<R9.0>]
        dec     r2                                                       ; push on stack
        str     r2                                                       
        shr                                                              ; add to self shifted right
        sex     r2                                                       
        add                                                              
        phi     r9                                                       ; update R9 high
        str     r6                                                       ; save at Vx
        sex     r6                                                       ; RX points to Vx
        lda     r5                                                       ; read low byte (mask)
        and                                                              ; and with Vx
        str     r6                                                       ; update
        inc     r2                                                       ; fix up stack and exit.
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;               9xys  Draw sxs pattern (5 or 8) x = pattern address in page 3 y = tv cell address.
;                                                        
;****************************************************************************************************************
opcode9:
        lda     r5                                                       ; Get next byte
        ani     0fh                                                      ; look at lower 4 bits which are size
        plo     rf                                                       ; RF.0 is the number of lines to do.

;****************************************************************************************************************
;                                                        
;                                                   RF = #lines
;                                                        
;****************************************************************************************************************

        sex     r6                                                       ; R(x) points to VX
        ldx                                                              ; read X
        plo     ra                                                       ; save in RA.0
        ldi     graphics / 256                                           ; RA is $03[Vx]
        phi     ra                                                       

;****************************************************************************************************************
;                                                        
;                  RF = #lines. RA = address of graphic data. Calc address from tv cell address.
;                       Bits 3,4 are the vertical cell position (0-3, 8 pixels high cell).
;                       Bits 0,1,2 are the horizontal position. (0-7, 8 pixels wide cell).
;                                                        
;****************************************************************************************************************

        lda     r7                                                       ; read Y (Cell number)
        plo     rb                                                       ; RB.0 = Y
        shr                                                              ; R6 = Y >> 1 << 4 (Y * 8)
        str     r6                                                       ; using shift left function, so bits
        sep     r8                                                       ; 3 and 4 are now in bits 6,7
        db      shiftvxleft4 & 255                                       
        glo     rb                                                       ; get original cell number for bits 0-2
        or                                                               ; or with bits 6-7
        ani     0c7h                                                     ; remove so only bits 0-2 and bits 6-7
        plo     rb                                                       
        ldi     screen/256                                               ; set RB.1 = 07<addr>
        phi     rb                                                       

copypixeldata:
        lda     ra                                                       ; read first byte of data
        str     rb                                                       ; write to the screen
        glo     rb                                                       ; get low byte of screen address
        adi     08                                                       ; go one row down
        plo     rb                                                       ; update screen address
        dec     rf                                                       ; decrement line counter.
        glo     rf                                                       ; check it
        bnz     copypixeldata                                            ; do next row.
        sep     r4                                                       

;****************************************************************************************************************
;                                                        
;                  0300 font data. First 16 bytes is offset for 0-9A-F required for the monitor.
;                                       Everything after that is optional.
;                                                        
;****************************************************************************************************************

graphics:
        db      graphic0 & 255                                           
        db      graphic1 & 255                                           
        db      graphic2 & 255                                           
        db      graphic3 & 255                                           
        db      graphic4 & 255                                           
        db      graphic5 & 255                                           
        db      graphic6 & 255                                           
        db      graphic7 & 255                                           
        db      graphic8 & 255                                           
        db      graphic9 & 255                                           
        db      graphica & 255                                           
        db      graphicb & 255                                           
        db      graphicc & 255                                           
        db      graphicd & 255                                           
        db      graphice & 255                                           
        db      graphicf & 255                                           
graphic1:
        db      010h                                                     ; ...X....
        db      030h                                                     ; ..XX....
        db      010h                                                     ; ...X....
        db      010h                                                     ; ...X....
graphic7:
        db      07ch                                                     ; .XXXXX..
        db      008h                                                     ; ....X...
        db      010h                                                     ; ...X....
        db      020h                                                     ; ..X.....
        db      040h                                                     ; .X......
graphic4:
        db      008h                                                     ; ....X...
        db      018h                                                     ; ...XX...
        db      028h                                                     ; ..X.X...
        db      07ch                                                     ; .XXXXX..
        db      008h                                                     ; ....X...
graphic9:
        db      038h                                                     ; ..XXX...
        db      044h                                                     ; .X...X..
        db      03ch                                                     ; ..XXXX..
        db      004h                                                     ; .....X..
graphicb:
        db      078h                                                     ; .XXXX...
        db      024h                                                     ; ..X..X..
        db      038h                                                     ; ..XXX...
        db      024h                                                     ; ..X..X..
graphicd:
        db      078h                                                     ; .XXXX...
        db      044h                                                     ; .X...X..
        db      044h                                                     ; .X...X..
        db      044h                                                     ; .X...X..
graphic3:
        db      078h                                                     ; .XXXX...
        db      004h                                                     ; .....X..
        db      018h                                                     ; ...XX...
        db      004h                                                     ; .....X..
graphic2:
        db      078h                                                     ; .XXXX...
        db      004h                                                     ; .....X..
        db      038h                                                     ; ..XXX...
        db      040h                                                     ; .X......
graphic5:
        db      07ch                                                     ; .XXXXX..
        db      004h                                                     ; .X..
        db      078h                                                     ; .XXXX...
        db      004h                                                     ; .....X..
        db      078h                                                     ; .XXXX...
graphice:
        db      07ch                                                     ; .XXXXX..
        db      040h                                                     ; .X......
        db      07ch                                                     ; .XXXXX..
        db      040h                                                     ; .X......
graphicf:
        db      07ch                                                     ; .XXXXX..
        db      040h                                                     ; .X......
        db      07ch                                                     ; .XXXXX..
        db      040h                                                     ; .X......
        db      040h                                                     ; .X......
graphicc:
        db      03ch                                                     ; ..XXXX..
        db      040h                                                     ; .X......
        db      040h                                                     ; .X......
        db      040h                                                     ; .X......
graphic6:
        db      03ch                                                     ; ..XXXX..
        db      040h                                                     ; .X......
        db      078h                                                     ; .XXXX...
        db      044h                                                     ; .X...X..
graphic0:
        db      038h                                                     ; ..XXX...
        db      044h                                                     ; .X...X..
        db      044h                                                     ; .X...X..
        db      044h                                                     ; .X...X..
graphic8:
        db      038h                                                     ; ..XXX...
        db      044h                                                     ; .X...X..
        db      038h                                                     ; ..XXX...
        db      044h                                                     ; .X...X..
graphica:
        db      038h                                                     ; ..XXX...
        db      044h                                                     ; .X...X..
        db      07ch                                                     ; .XXXXX..
graphich:
        db      044h                                                     ; .X...X..
        db      044h                                                     ; .X...X..
        db      07ch                                                     ; .XXXXX..
graphicu:
        db      044h                                                     ; .X...X..
        db      044h                                                     ; .X...X..
        db      044h                                                     ; .X...X..
        db      044h                                                     ; .X...X..
graphicqmark:
        db      038h                                                     ; ..XXX...
        db      044h                                                     ; .X...X..
        db      008h                                                     ; ....X...
graphicapostrophe:
        :       db 010h                                                  ; ...X....
        db      010h                                                     ; ...X....
graphicspace:
        db      000h                                                     ; ........
graphiculine:
        db      000h                                                     ; ........
        db      000h                                                     ; ........
graphicminus:
        db      000h                                                     ; ........
        db      000h                                                     ; ........
        db      07ch                                                     ; .XXXXX..
        db      000h                                                     ; ........
graphicequals:
        db      000h                                                     ; ........
        db      07ch                                                     ; .XXXXX..
        db      000h                                                     ; ........
        db      07ch                                                     ; .XXXXX..
        :       db 000h                                                  ; ........
        db      018h                                                     ; ...XX...
        db      000h                                                     ; ........
        db      018h                                                     ; ...XX...
        db      000h                                                     ; ........

;****************************************************************************************************************
;                                                        
;                                              Versions and Changes.
;                                                        
;                           13/07/2016 First complete and correctly attributed version.
;                                                        
;****************************************************************************************************************
