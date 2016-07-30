@echo off
python ..\..\uForth\ufc.py
copy /Y a.out ..\..\build\deduce.bin
..\..\emulator\fredii.exe a.out