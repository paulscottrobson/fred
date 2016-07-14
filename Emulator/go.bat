\mingw\bin\asw -L core.asm
if errorlevel 1 goto norun
\mingw\bin\p2bin -r 0-511 -l 0 core.p
del core.p
python toinclude.py
fredii core.bin
:norun
