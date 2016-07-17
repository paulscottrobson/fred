code = """
400		0078 	Clear Display
402		21C0 	V1 = 0C0h 			(Pattern #)
404		2200	V2 = 10h 			(Cell#)
406 	2301 	V3 = 01 			(Centre)

408 	B600 	B = 600 			Set B to point to $600
40A 	1422 	CALL 422 			Call 422 for C0,C5,CA,CA,BC,B5
40C 	21C5 	V1 = C5 			Print PUZZLE.
40E 	1422 	CALL 422
410 	21CA 	V1 = CA
412 	1422 	CALL 422
414 	21CA 	V1 = CA
416 	1422 	CALL 422
418 	21BC 	V1 = BC
41A 	1422 	CALL 422
41C 	21B5 	V1 = B5
41E 	1422 	CALL 422
420 	F430 	GOTO 430 		Skip over 422 code.


422 	7134 	V1->LSB of (B)	So B is now (say) $6C5
424		7121 	Read $6C5 into V1
426 	8234 	Says V2 + V3 -> V2 which makes more sense.
428 	9125 	Write graphic V1 and position V2. 5 high.
42A 	026E 	Return.

42C 	E47A 	Keyboard on, wait for key to V4.
42E 	F438 	Goto 438

430 	0078 	Clear Screen
432		F42C 	Goto 42C

438 	0078 	Clear Screen
43A 	2700 	V7 = 0 (timer)
43C 	21F0 	V1 = F0
43E 	2200	V2 = 0
440 	1450	Call 450

"""


