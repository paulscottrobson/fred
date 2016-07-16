@echo off
del fel.bin
del fel_src.bin
python process.py
\mingw\bin\asw -L fel.asm
if errorlevel 1 goto end
\mingw\bin\p2bin -r 0-1023 -l 0 fel.p
del fel_source.zip
zip fel_source.zip *
fc /b fel.bin fel_src.bin
copy /Y __fel1.h ..\Emulator
copy /Y fel.bin ..\Emulator
..\emulator\fredii.exe fel.bin
:end