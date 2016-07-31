@echo off
python ..\..\uForth\ufc.py
copy /Y a.out ..\..\build\spacewar.bin
..\..\emulator\fredii.exe a.out