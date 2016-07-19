@echo off
\mingw\bin\asw -L uforth.asm
if errorlevel 1 goto end
\mingw\bin\p2bin -r 0-1023 -l 0 uforth.p
..\emulator\fredii.exe uforth.bin
:end