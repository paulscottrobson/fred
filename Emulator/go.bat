@echo off
set ASMFILE=test
\mingw\bin\asw -L %ASMFILE%.asm
if errorlevel 1 goto norun
\mingw\bin\p2bin -r 0-511 -l 0 %ASMFILE%.p
del %ASMFILE%.p
python toinclude.py
fredii %ASMFILE%.bin
:norun
