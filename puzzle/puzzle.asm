
    include "fel.asm"														; FEL-1 interpreter 
    include "extendedFont.inc" 												; extra font (36F-3FF)
    include "extendedIndex.inc" 											; font index (6B0-6F0)
    
    org     03C0h															; graphics specific to puzzle
    include "graphics.inc" 													; (will cause warning)
    
    org     0400h
    