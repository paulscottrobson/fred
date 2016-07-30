@echo off
python ..\..\uForth\ufc.py
copy /Y a.out ..\..\build\jackpot.bin
..\..\emulator\fredii.exe a.out