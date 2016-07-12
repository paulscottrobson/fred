@echo off
python process.py
\mingw\bin\asw -L fel.asm
\mingw\bin\p2bin -r 0-1023 -l 0 fel.p
fc /b fel.bin fel_src.bin
del fel_source.zip
zip fel_source.zip *