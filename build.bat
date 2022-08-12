@echo off
rem Build CPC For RC2014 variants
rem ---

rem See README.md for full instructions

rem  See Main.asm for available build settings
rem Add other build settings to rasm with -D<label>=<value>

rem Dependencies:
rem rasm assembler
rem srec_cat format converter

echo Building 'basic' flat memory model version for Pageable ROM board etc.
rem Assemble binary
rasm main.asm -Dflat=1 -ob flat.bin
rem Convert to hex
srec_cat flat.bin -binary -offset 0x0000 -o flat.hex
echo.

echo Building flat memory model version for 512k RAM 512k ROM module
rem Assemble binary
rasm main.asm -Dflat=1 -Dk512=1 -ob k512flat.bin
rem Convert to hex
srec_cat k512flat.bin -binary -offset 0x0000 -o k512flat.hex
echo.

rem Uncomment this line if you need to convert BASIC to hex
rem srec_cat BASIC1.1.bin -binary -offset 0xc000 -o BASIC1.1.hex -intel

echo Build CPC For RC2014 complete
