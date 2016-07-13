// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		hardware.cpp
//		Purpose:	Hardware Interface
//		Created:	21st June 2016
//		Author:		Paul Robson (paul@robsons.org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#include <stdlib.h>
#include "sys_processor.h"
#include "hardware.h"

#ifdef WINDOWS
#include <stdio.h>
#include "gfx.h"																// Want the keyboard access.
#endif

static BYTE8 rows,columns;														// Screen size.
static WORD16 renderingAddress; 												// Screen rendering address
static BYTE8 keyAvailable; 														// Key pressed - $FF if not.
static WORD16 snd0Time,snd1Time; 												// Time sound got value
static BYTE8 isScreenOn;														// Non zero if screen on
// *******************************************************************************************************************************
//													Hardware Reset
// *******************************************************************************************************************************

void HWIReset(void) {
	keyAvailable = 0xFF; 
	columns = 64;rows = 32;
	isScreenOn = 0;
	renderingAddress = 0x0000;
	snd0Time = snd1Time = 0;
	GFXSetFrequency(0);
}

// *******************************************************************************************************************************
//											Process keys passed from debugger
// *******************************************************************************************************************************

#ifdef WINDOWS
BYTE8 HWIProcessKey(BYTE8 key,BYTE8 isRunMode) {
	if (isRunMode) {										
		if (key >= '0' && key <= '9') keyAvailable = key - '0';					// Process hex
		if (key >= 'a' && key <= 'f') keyAvailable = key - 'a' + 10;
		if (GFXIsKeyPressed(GFXKEY_SHIFT)) keyAvailable |= 0x10; 				// Bit 4 is the 'shift' key.
	}
	return key;
}
#endif

// *******************************************************************************************************************************
//												Called at End of Frame
// *******************************************************************************************************************************

WORD16 HWIEndFrame(WORD16 r0,LONG32 clock) {
	renderingAddress = r0; 														// the rendering address is what R0 was set to last time.

	if (snd0Time != 0 && snd1Time != 0) {
		WORD16 cycles = abs(snd0Time-snd1Time); 								// Cycles per half cycle
		cycles = cycles * 2 * 8;	 											// make whole clocks, 8 per cycle.
		LONG32 freq = 1000000 / cycles; 										// Pitch
		GFXSetFrequency(freq);
	} else {
		GFXSetFrequency(0);
	}
	snd0Time = snd1Time = 0;
	return r0;																	// Return what R0 should be on entering interrupt.
}

// *******************************************************************************************************************************
//													Check if screen on
// *******************************************************************************************************************************

BYTE8 HWIIsScreenOn(void) {
	return isScreenOn;
}

// *******************************************************************************************************************************
//								Access screen dimensions (64 or 32 pixels, 32 or 16 rows)
// *******************************************************************************************************************************

BYTE8 HWIScreenWidth(void) { 
	return columns;
}

BYTE8 HWIScreenHeight(void) {
	return rows;
}
// *******************************************************************************************************************************
//													Set the rendering address
// *******************************************************************************************************************************

WORD16 HWIGetDisplayAddress(void) {
	return renderingAddress;
}
