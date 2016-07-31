// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		sys_debug_fred.c
//		Purpose:	Debugger Code (System Dependent)
//		Created:	21st June 2016
//		Author:		Paul Robson (paul@robsons->org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gfx.h"
#include "sys_processor.h"
#include "debugger.h"
#include "hardware.h"

static const char *_mnemonics[256] = {
#include "_1801_disasm.h"
};

#define DBGC_ADDRESS 	(0x0F0)														// Colour scheme.
#define DBGC_DATA 		(0x0FF)														// (Background is in main.c)
#define DBGC_HIGHLIGHT 	(0xFF0)

// *******************************************************************************************************************************
//											This renders the debug screen
// *******************************************************************************************************************************

static const char *labels[] = { "D","DF","P","X","T","IE","RP","RX","CY","BP", NULL };

void DBGXRender(int *address,int runMode) {
	int n = 0;
	char buffer[32];
	CPUSTATUS *s = CPUGetStatus();
	GFXSetCharacterSize(32,23);
	DBGVerticalLabel(15,0,labels,DBGC_ADDRESS,-1);									// Draw the labels for the register

	#define DN(v,w) GFXNumber(GRID(18,n++),v,16,w,GRIDSIZE,DBGC_DATA,-1)			// Helper macro

	n = 0;
	DN(s->d,2);DN(s->df,1);DN(s->p,1);DN(s->x,1);DN(s->t,2);DN(s->ie,1);			// Registers
	DN(s->pc,4);DN(s->r[s->x],4);DN(s->cycles,4);DN(address[3],4);					// Others

	for (int i = 0;i < 16;i++) {													// 16 bit registers
		sprintf(buffer,"R%x",i);
		GFXString(GRID(i % 4 * 8,i/4+12),buffer,GRIDSIZE,DBGC_ADDRESS,-1);
		GFXString(GRID(i % 4 * 8+2,i/4+12),":",GRIDSIZE,DBGC_HIGHLIGHT,-1);
		GFXNumber(GRID(i % 4 * 8+3,i/4+12),s->r[i],16,4,GRIDSIZE,DBGC_DATA,-1);
	}

	int a = address[1];																// Dump Memory.
	for (int row = 17;row < 23;row++) {
		GFXNumber(GRID(2,row),a,16,4,GRIDSIZE,DBGC_ADDRESS,-1);
		GFXCharacter(GRID(6,row),':',GRIDSIZE,DBGC_HIGHLIGHT,-1);
		for (int col = 0;col < 8;col++) {
			GFXNumber(GRID(7+col*3,row),CPUReadMemory(a),16,2,GRIDSIZE,DBGC_DATA,-1);
			a = (a + 1) & 0xFFFF;
		}		
	}

	int p = address[0];																// Dump program code. 
	int opc;

	for (int row = 0;row < 11;row++) {
		int isPC = (p == ((s->pc) & 0xFFFF));										// Tests.
		int isBrk = (p == address[3]);
		GFXNumber(GRID(0,row),p,16,4,GRIDSIZE,isPC ? DBGC_HIGHLIGHT:DBGC_ADDRESS,	// Display address / highlight / breakpoint
																	isBrk ? 0xF00 : -1);
		opc = CPUReadMemory(p);p = (p + 1) & 0xFFFF;								// Read opcode.
		strcpy(buffer,_mnemonics[opc]);												// Work out the opcode.
		char *at = buffer+strlen(buffer)-2;											// 2nd char from end
		if (*at == '.') {															// Operand ?
			if (at[1] == '1') {
				sprintf(at,"%02x",CPUReadMemory(p));
				p = (p+1) & 0xFFFF;
			}
		}
		GFXString(GRID(5,row),buffer,GRIDSIZE,isPC ? DBGC_HIGHLIGHT:DBGC_DATA,-1);	// Print the mnemonic
	}


	int width = HWIScreenWidth();													// Get screen display resolution.
	int height = HWIScreenHeight();
	int ramAddress = HWIGetDisplayAddress();

	SDL_Rect rc;rc.x = _GFXX(21);rc.y = _GFXY(1)/2;									// Whole rectangle.
	rc.w = 11 * GRIDSIZE * 6;rc.h = 5 *GRIDSIZE * 8; 										
	if (runMode != 0) {
		rc.w = WIN_WIDTH * 8 / 10;rc.h = WIN_HEIGHT * 4/10;
		rc.x = WIN_WIDTH/2-rc.w/2;rc.y = WIN_HEIGHT - rc.h - 64;
	}
	rc.w = rc.w/width*width;rc.h = rc.h/height*height;								// Make equal size pixels.

	if (!HWIIsScreenOn()) {															// Screen off, show static.
		SDL_Rect rcp;		
		rcp.w = rcp.h = rc.w/256;if (rcp.w == 0) rcp.w = rcp.h = 1;
		GFXRectangle(&rc,0x00000000);
		for (rcp.x = rc.x;rcp.x <= rc.x+rc.w;rcp.x += rcp.w)
			for (rcp.y = rc.y;rcp.y <= rc.y+rc.h;rcp.y += rcp.h) {
				if (rand() & 1) GFXRectangle(&rcp,0xFFFFFF);
			}
		return;		
	}

	SDL_Rect rcPixel;rcPixel.h = rc.h/height;rcPixel.w = rc.w / width;				// Pixel rectangle.
	SDL_Rect rcDraw;rcDraw.w = rcPixel.w/2;rcDraw.h = rcPixel.h/2;
	GFXRectangle(&rc,0x0);															// Fill it black
	for (int j = 0;j < height;j++) {
		for (int i = 0;i < width;i += 8) {
			BYTE8 vRam = CPUReadMemory(ramAddress++);
			for (int b = 0;b < 8;b++) {
				if (vRam & (0x80 >> b))
				{
					rcDraw.x =  rc.x + (i+b) * rcPixel.w;
					rcDraw.y = rc.y + j * rcPixel.h;
					GFXRectangle(&rcDraw,0xFFFFFF);
				}
			}
		}
	}
}	