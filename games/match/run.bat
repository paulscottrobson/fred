@echo off
python ..\..\uForth\ufc.py
copy /Y a.out ..\..\build\match.bin
..\..\emulator\fredii.exe a.out