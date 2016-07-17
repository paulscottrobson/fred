@echo off
\mingw\bin\asw -L -i ..\fel-1 puzzle.asm
if errorlevel 1 goto end
\mingw\bin\p2bin -r 0-2047 -l 0 puzzle.p
rem ..\emulator\fredii.exe fel.bin
:end