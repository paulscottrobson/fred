@echo off
python ..\..\uForth\ufc.py
copy /Y a.out ..\..\build\acey.bin
..\..\emulator\fredii.exe a.out