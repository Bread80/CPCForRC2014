;CPC For RC2014 Term(inal)

include "HexLoader.asm"

term_rsx_header:
    defw term_name_table
    
    jp term_rsx

term_name_table:
    defb "TER","M"+$80
    defb 0
    
    ;DE=first usable byte of memory
    ;HL=last usable byte of memory
    ;Out: AF,BC corrupt. All other registers preserved.
term_install:
    push de
    dec hl              ;KL_LOG EXT needs 4 bytes of memory
    dec hl
    dec hl
    push hl             ;Which we'll return
    
    ld bc,term_rsx_header   ;Log our commands
    call KL_LOG_EXT
    
    ld hl,term_install_message  ;Show sign-on string
    call display_a_null_terminated_string
    
    pop hl
    dec hl              ;Point HL to byte below our first
    pop de
    ret

term_install_message:    
    defb " CPC for RC2014 Term",13,10,0
    
term_boot:
    ld hl,_startup_entry_point_27   ; If we return from Term we'll continue booting
    push hl
ifdef mem_base
    ld ix,mem_base
else
    ld ix,$4000
endif
    jr term_help
    
term_rsx:
    and a                   ;Zero parameters?
    ld hl,$ac8a             ;BASIC 1.1 edit buffer address
    jr z,term
    
    ld l,(ix)               ;Read buffer address from first parameter
    ld h,(ix+1)
term:
    push hl
    pop ix                  ;Store edit buffer address in IX
    
    ld hl,term_welcome_message
    call display_a_null_terminated_string
    
term_loop:
    call TXT_CUR_ON
    call SERIAL_WAIT       ;Wait for a char
    cp ':'
    jr z,dl_hex_file        ;Start of hex file marker
    cp $1b                  ;ESCape
    ret z                   ;Break back to caller
    
    call KM_CHAR_RETURN     ;Put the char back so the editor can read it
    push ix
    pop hl
    ld (hl),0               ;Clear buffer
    call EDIT               ;Call line the editor
    ret nc                  ;No carry = break
    
    ld a,(hl)
    and a                   ;Empty buffer
    jr z,term_empty_buffer
    cp '?'
    jr z,term_help
    or $20                  ;Convert to lower case
    cp 'r'
    jp z,_startup_entry_point_27 ;Hook into normal bootup process
    ;Process more command line options here
    
    ld hl,term_error_message
    call display_a_null_terminated_string 
    jr term_loop
    
term_empty_buffer
    call performs_control_character_LF_function
    jr term_loop
    
term_help:
    ld hl,term_help_message
    call display_a_null_terminated_string
    jr term_loop
    
dl_hex_file:
    call HexLoad
    jr term_loop
    
term_boot_to_rom:

    
term_welcome_message:
    defb "Paste an Intel hex file or ? for help",13,10,0
term_error_message:
    defb 13,10,"Sorry, didn't quite catch that",13,10,0
    
term_help_message:
    defb 13,10,"CPC for RC2014 Term",13,10,10
    defb "Paste an Intel hex file into your",13,10,"terminal. It'll be poked into the",13,10,"address in the file.",13,10
    defb "? - show this help",13,10
    defb "r - boot to foreground ROM",13,10
    defb "ESC - return to whatever called me",13,10,0

