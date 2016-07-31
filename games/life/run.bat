@echo off
python ..\..\uForth\ufc.py
copy /Y a.out ..\..\build\life.bin
..\..\emulator\fredii.exe a.out