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

442 	7121 	Read Mem(B) to V1.
444 	2201	V2 = 1
446 	1450 	Call 450

448 	21F1 	V1 = F1
44A 	2208	V2 = 8
44C 	1450 	Call 450

44E 	F458 	Goto 458
;
;	Read [$0600+V1] and display pattern at V2
;
450 	7134 	B = 6[V1]
452 	7121 	V1 = M[B]
454 	912B 	8x8 Pattern address in V1, Cell in V2.
456 	026E 	Return

458 	025C 	TV On
45A 	21F5 	V1 = F5
45C		220E 	V2 = 0E
45E 	1450 	Call 450

460 	21F3 	V1 = F3
462 	2215 	V2 = 15
464 	1450 	Call 450

466		7448 	Delay V4
468 	E480	Get Key Skip if None
46A 	1490	Key goto 1490


"""


