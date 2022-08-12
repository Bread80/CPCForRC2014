;#dialect=RASM

; Amstrad CPC Firmware converted to run on an RC2014

;Build options. Uncomment to include, comment out to remove.

cpc equ 0       ;DO NOT ALTER - used to comment out unwanted CPC code

ifndef flat     ;Only if not passed in as a parameter
    flat equ 1      ;Use a flat memory model, with RAM starting at &4000
endif

;k512 equ 1     ;Uncomment for 512K ROM/RAM board
ifdef k512      ;Default memory banks to use for 512K ROM/RAM variant
    ifndef basebankio
    basebankio  equ &78 ;The I/O port for the first 16Kb memory bank/page
    endif

    ifndef lowrompage
    lowrompage  equ 0   ;The page (bank) to use for the firmware (lower ROM)
    endif
    ifndef ramstart
    ramstart    equ 17  ;The first page (bank) to use for RAM. This bank will be used
                        ;for addresses &0000 to &3fff (if used for RAM) and the
                        ;rest of RAM will use subsequent banks
    endif
    ifndef upperromstart
    upperromstart equ 16 ;The page (bank) containing ROM 0 (usually BASIC)
                        ;When CPC banking support is added additional ROMs will be found
                        ;in subsequent banks.
    endif
endif

;mem_base equ $8000      ;Sets the lowest RAM address to use. Only necessary if the 'normal' address range
                        ;is not available. Note: the 'flat' setting sets lowest RAM addr to $4000, but can 
                        ;be overridden by setting mem_base

;Serial port options
;"A" uses port A, "B" uses port B
ifndef serial_input_port
    serial_input_port equ "A"      
endif
ifndef serial_output_port
    serial_output_port equ "A"
endif

;interrupts equ 1   ;Uncomment if your system has suitable interrupts (300 per second recommended)

;Labels/constants
include "Includes/JumpblockHigh.asm"
include "Includes/JumpblockIndirections.asm"
include "Includes/MemoryFirmware.asm"

;; KERNEL ROUTINES
include "asm/LowJumpblock.asm"
include "asm/Kernel.asm"
include "asm/HighJumpblock.asm"
include "asm/Machine.asm"
include "asm/CPCSerial.asm"
include "asm/Term.asm"
include "asm/JumpRestore.asm"
include "asm/Screen.asm"
include "asm/Text.asm"
include "asm/Graphics.asm"
include "asm/Keyboard.asm"
include "asm/Sound.asm"
include "asm/Cassette.asm"
include "asm/LineEditor.asm"
include "asm/FPMaths.asm"
include "asm/Font.asm"
