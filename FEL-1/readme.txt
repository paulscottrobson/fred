Notes:

I typed in the FEL-1 listing from the BJC papers - including 1802 Assembler and the object code.
This file is fel.src

The file process.py takes this and converts it to an assembler only file fel.asm and a binary file
fel_src.bin

The font data is held in font.txt and fills up (mostly) page 3. It is split into two parts, as far as
$36E (which has an index $300-$30F). This is part of FEL-1 itself (i.e. it is required for the 
monitor). The remainder occupies the rest of page 3 and has an index from $6B0-$6EE (for Puzzle anyway)

The font data originates partly from the BJC papers and partly is created by me - we have the index data
for the font characters after $36E but not the font data itself.

This source file is assembled using Alfred Arnold's AS freeware assembler and compared against the typed
in binary code.

Paul Robson 12 July 2016

