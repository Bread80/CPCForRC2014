rasm matrix.asm -ob matrix
srec_cat matrix.bin -binary -offset 0x8000 -o matrix.hex -intel