// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		hardware.h
//		Purpose:	Hardware Interface (header)
//		Created:	21st June 2016
//		Author:		Paul Robson (paul@robsons.org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#ifndef _HARDWARE_H
#define _HARDWARE_H

BYTE8 HWIProcessKey(BYTE8 key,BYTE8 isRunMode);
WORD16 HWIEndFrame(WORD16 r0,LONG32 clock);
void HWIReset(void);
BYTE8 HWIScreenWidth(void);
BYTE8 HWIScreenHeight(void);
WORD16 HWIGetDisplayAddress(void);
BYTE8 HWIIsScreenOn(void);
void HWIWriteDevice(BYTE8 device,BYTE8 controlValue);
BYTE8 HWIGetCurrentKeyLatch(void);
BYTE8 HWIIsKeyAvailable(void);
#endif
