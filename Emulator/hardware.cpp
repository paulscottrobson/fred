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
static WORD16 snd0Time,snd1Time; 												// Time sound got value
static BYTE8 isScreenOn;														// Non zero if screen on
static BYTE8 isKeypadOn;														// Non zero if keypad on.
static BYTE8 keypadLatch; 														// State of keypad latch
static BYTE8 isLatchKeyAvailable; 												// Is byte/key data available.

static void HWIHandleKeyEvent(BYTE8 hexValue,BYTE8 shiftPressed);

// *******************************************************************************************************************************
//													Hardware Reset
// *******************************************************************************************************************************

void HWIReset(void) {
	columns = 64;rows = 32;														// Standard screen size
	isScreenOn = 0; 															// Screen off
	renderingAddress = 0x0000; 
	snd0Time = snd1Time = 0; 													// No audio
	GFXSetFrequency(0);
	keypadLatch = 0;															// Keypad latch empty
	isLatchKeyAvailable = 0;													// No key available.
	isKeypadOn = 0;																// Keypad circuitry on.
}

// *******************************************************************************************************************************
//											Process keys passed from debugger
// *******************************************************************************************************************************

#ifdef WINDOWS
BYTE8 HWIProcessKey(BYTE8 key,BYTE8 isRunMode) {
	if (isRunMode) {
		BYTE8 hex = 0xFF;
		if (key >= '0' && key <= '9') hex = key - '0';							// Process hex
		if (key >= 'a' && key <= 'f') hex = key - 'a' + 10;
		if (hex != 0xFF) {														// If 0-9A-F pressed call handler
			HWIHandleKeyEvent(hex,GFXIsKeyPressed(GFXKEY_SHIFT));
		}
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
//										Handle key press event.
// *******************************************************************************************************************************

static void HWIHandleKeyEvent(BYTE8 hexValue,BYTE8 shiftPressed) {
	if (isKeypadOn != 0) { 														// Nothing happens if keypad off
		if (1) {	 															// Nibble mode.
			keypadLatch = hexValue;												// Put hex value in keypad latch
			if (shiftPressed != 0) keypadLatch |= 0x10;							// Set bit 4 if shift pressed.
			isLatchKeyAvailable = 1;											// Key is now available
		} else {
			// Byte entry mode, not implemented yet.
		}
	}
}

// *******************************************************************************************************************************
//						Write to device selected via port 1, control command via port 2
// *******************************************************************************************************************************

void HWIWriteDevice(BYTE8 device,BYTE8 controlValue) {
	//printf("DC:%x %x\n",device,controlValue);

	switch(device) {
		case 1:																	// Device 1 = Keypad
			isKeypadOn = (controlValue & 1) != 0;								// 0 off 1 on in lower bit.
			break;
		case 2:																	// Device 2 = TV.
			isScreenOn = (controlValue & 3) == 3; 								// 00 off 11 on in 2 lower bits.
			break;
	}
}

// *******************************************************************************************************************************
//											Get state of keyboard input latch
// *******************************************************************************************************************************

BYTE8 HWIGetCurrentKeyLatch(void) {
	BYTE8 r =  (isKeypadOn != 0) ? keypadLatch : 0;								// Read keypad latch if on.
	isLatchKeyAvailable = 0;													// Has been read so clear available latch.
	return r;					
}

// *******************************************************************************************************************************
//											Check if key available for reading
// *******************************************************************************************************************************

BYTE8 HWIIsKeyAvailable(void) {
	return isLatchKeyAvailable;
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