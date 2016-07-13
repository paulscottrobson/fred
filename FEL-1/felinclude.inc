;****************************************************************************************************************
;
;													1802 Includes
;
;****************************************************************************************************************

	cpu 1802

r0 = 0 															; register definitions
r1 = 1
r2 = 2
r3 = 3
r4 = 4
r5 = 5
r6 = 6
r7 = 7
r8 = 8
r9 = 9
ra = 10
rb = 11
rc = 12
rd = 13
re = 14
rf = 15

keypadPort = 0 													; keypad read (in only)
selectDevice = 1 												; select DMA device (tape 3 tv 2 keypad 1)
controlDevice = 2 												; control of selected device
audioControl = 3  												; control tape/audio
externalControl = 4 											; external control register (used in monitor)

externalBus = 6 												; external bus (in/out)

screen = 0700h													; screen RAM is here.

devKeypad = 1 													; device IDs for port 1
devTV = 2
devTape = 3

cKeyOff = 0 													; controls for keyboard, TV and Tape
cKeyOn = 1 														; for port 2.
cTVOn = 3
cTVOff = 0
cTapeRead = 20h

aSpeakerBit = 4 												; bit 2 is speaker out
aTapeBit = 2 													; bit 1 is tape out
aConnect = 1 													; bit 0 seems to be 1 to connect it.

fel macro 	fw 													; compile FEL-1 instruction in Hi-Low order
	db 	(fw) / 256
	db 	(fw) & 255
	endm
