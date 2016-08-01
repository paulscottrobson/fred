@echo off
python ..\..\uForth\ufc.py
copy /Y a.out ..\..\build\acey.bin
copy /Y *.u4 ..\..\build\forth
..\..\emulator\fredii.exe a.out