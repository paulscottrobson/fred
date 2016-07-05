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
#include "gfx.h"																// Want the keyboard access.
#endif

static BYTE8 screenControlPort; 												// Screen control 
static WORD16 renderingAddress; 												// Screen rendering address
static BYTE8 keyAvailable; 														// Key pressed - $FF if not.

// *******************************************************************************************************************************
//													Hardware Reset
// *******************************************************************************************************************************

void HWIReset(void) {
	keyAvailable = 0xFF; 
	screenControlPort = 0x03;
	renderingAddress = 0x00;
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

WORD16 HWIEndFrame(WORD16 r0) {
	renderingAddress = r0; 														// the rendering address is what R0 was set to last time.
	r0 = r0 + HWIScreenWidth() * HWIScreenHeight() / 8; 						// this is what R0 should be after display rendering.
	if (keyAvailable != 0xFF) { 												// Key pressed ?
		CPUWriteMemory(r0,keyAvailable);										// Write the key in memory there.
		r0++;	 																// and bump R0 - e.g. effectively DMA In the key.
		keyAvailable = 0xFF;													// And clear key available flag.
	}
	return r0;																	// Return what R0 should be on entering interrupt.
}

// *******************************************************************************************************************************
//									   Written to the control port (currently port 2)
//									(bit 0: 64 Columns, bit 1: 32 rows, bit 7: sound line)
// *******************************************************************************************************************************

void HWIWriteControlPort(BYTE8 portValue) {
	screenControlPort = portValue; 
}

// *******************************************************************************************************************************
//								Access screen dimensions (64 or 32 pixels, 32 or 16 rows)
// *******************************************************************************************************************************

BYTE8 HWIScreenWidth(void) { 
	return (screenControlPort & 0x01) ? 64 : 32; 
}

BYTE8 HWIScreenHeight(void) {
	return (screenControlPort & 0x02) ? 32 : 16; 	
}
// *******************************************************************************************************************************
//													Set the rendering address
// *******************************************************************************************************************************

WORD16 HWIGetDisplayAddress(void) {
	return renderingAddress;
}
