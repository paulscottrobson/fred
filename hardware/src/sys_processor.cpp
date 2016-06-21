// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		processor.c
//		Purpose:	Processor Emulation.
//		Created:	21st June 2016
//		Author:		Paul Robson (paul@robsons.org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#include <stdlib.h>
#ifdef WINDOWS
#include <stdio.h>
#endif
#include "sys_processor.h"
#include "sys_debug_system.h"
#include "hardware.h"

// *******************************************************************************************************************************
//														   Timing
// *******************************************************************************************************************************

#define CRYSTAL_CLOCK 	(1000000L)													// Clock cycles per second (1.0 Mhz)
#define CYCLE_RATE 		(CRYSTAL_CLOCK/8)											// Cycles per second (8 clocks per cycle)
#define FRAME_RATE		(60)														// Frames per second (60)
#define CYCLES_PER_FRAME (CYCLE_RATE / FRAME_RATE)									// Cycles per frame (2,083 cycles per frame)

//	3,668 Cycles per frame
// 	262 lines per video frame
//	14 cycles per scanline (should be :))

// *******************************************************************************************************************************
//														CPU / Memory
// *******************************************************************************************************************************

static BYTE8   	D,DF,X,P,T,IE,temp8;
static WORD16   R[16],temp16,cycles;

static BYTE8 ramMemory[MEMORYSIZE];													

// *******************************************************************************************************************************
//											 Memory and I/O read and write macros.
// *******************************************************************************************************************************

#define MEMORYMASK  ((MEMORYSIZE)-1)

#define READ(a) 	ramMemory[(a) & MEMORYMASK]
#define WRITE(a,d) 	ramMemory[(a) & MEMORYMASK] = (d)

// *******************************************************************************************************************************
//													   Port Interfaces
// *******************************************************************************************************************************

#include "_1801_include.h"
#include "_1801_ports.h"

// *******************************************************************************************************************************
//														Reset the CPU
// *******************************************************************************************************************************

void CPUReset(void) {
	HWIReset();
	RESET();
}

// *******************************************************************************************************************************
//												Execute a single instruction
// *******************************************************************************************************************************

BYTE8 CPUExecuteInstruction(void) {

	BYTE8 opcode = FETCH();															// Fetch opcode

	switch(opcode) {																// Execute it.
		#include "_1801_opcodes.h"
	}
	cycles = cycles + 2;															// 2 cycles per instruction
	if (cycles < CYCLES_PER_FRAME) return 0;										// Not completed a frame.
	// TODO: Display using R0
	// TODO: Fire new interrupt.
	HWIEndFrame();																	// End of Frame code
	cycles = cycles - CYCLES_PER_FRAME;												// Adjust this frame rate.
	return FRAME_RATE;																// Return frame rate.
}

#ifdef INCLUDE_DEBUGGING_SUPPORT

// *******************************************************************************************************************************
//		Execute chunk of code, to either of two break points or frame-out, return non-zero frame rate on frame, breakpoint 0
// *******************************************************************************************************************************

BYTE8 CPUExecute(WORD16 breakPoint1,WORD16 breakPoint2) { 
	do {
		BYTE8 r = CPUExecuteInstruction();											// Execute an instruction
		if (r != 0) return r; 														// Frame out.
	} while (R[P] != breakPoint1 && R[P] != breakPoint2);							// Stop on breakpoint.
	return 0; 
}

// *******************************************************************************************************************************
//									Return address of breakpoint for step-over, or 0 if N/A
// *******************************************************************************************************************************

WORD16 CPUGetStepOverBreakpoint(void) {
	BYTE8 opcode = CPUReadMemory(R[P]);												// Current opcode.
	if (opcode >= 0xD0 && opcode <= 0xDF) return (R[P]+1) & 0xFFFF;					// If SEP Rx then step is one after.
	return 0;																		// Do a normal single step
}

// *******************************************************************************************************************************
//												Read/Write Memory
// *******************************************************************************************************************************

BYTE8 CPUReadMemory(WORD16 address) {
	return READ(address);
}

void CPUWriteMemory(WORD16 address,BYTE8 data) {
	WRITE(address,data);
}

// *******************************************************************************************************************************
//												Load a binary file into RAM
// *******************************************************************************************************************************

#include <stdio.h>

void CPULoadBinary(const char *fileName) {
	FILE *f = fopen(fileName,"rb");
	fread(ramMemory,1,MEMORYSIZE,f);
	fclose(f);
}

// *******************************************************************************************************************************
//											Retrieve a snapshot of the processor
// *******************************************************************************************************************************

static CPUSTATUS s;																	// Status area

CPUSTATUS *CPUGetStatus(void) {
	s.d = D;s.df = DF;s.p = P;s.x = X;s.t = T;s.ie = IE;							// Registers
	for (int i = 0;i < 16;i++) s.r[i] = R[i];										// 16 bit Registers
	s.cycles = cycles;s.pc = R[P];													// Cycles and "PC"
	return &s;
}

#endif
