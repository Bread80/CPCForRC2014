
include "SerialSIO2.asm"

;;======================
;Initialise the serial port IC.
SERIAL_INIT:
    jp RC2014_SerialSIO2_Initialise_T2

;;===========================================
;Output a character to the serial port (RC2014)
;In: A=character to send
;Out: Everything preserved
SERIAL_OUT:
    push af
    
serial_out_loop:
if serial_output_port == "A"
    call RC2014_SerialSIO2A_OutputChar_T2
else
    call RC2014_SerialSIO2B_OutputChar_T2
endif
    jr z,serial_out_loop
    
    pop af
    ret
    
;;========================
;Output an inline ASCIIZ string to the serial port
;Preserves *all* registers
;Useful for sending debug messages
;Usage:
;   call SERIAL_INLINE
;   defb "Message here",0
;   ...                     ;More code here
;Out: All registers and flags preserved
SERIAL_INLINE:
    ex (sp),hl              ;Retrieve return address aka inline data
    push af
    
message_loop:
    ld a,(hl)
    and a                   ;ASCIIZ string - test for zero
    jr z,serial_inline_done
    
send_loop:
if serial_output_port == "A"
    call RC2014_SerialSIO2A_OutputChar_T2   ;Send char to SIO
else
    call RC2014_SerialSIO2B_OutputChar_T2   ;Send char to SIO
endif
    jr z,send_loop          ;SIO busy - try again
    
    inc hl                  ;Next char
    jr message_loop

serial_inline_done:
    pop af
    inc hl                  ;Advance past the end-of-string marker
    ex (sp),hl              ;Put new return address back on stack
    ret

;====================================
;Fetch a character from the serial port
;Out:
;   If a character was read:
;       A=the character
;       Zero flag set
;   otherwise:
;       Zero flag clear
;       A and other flags corrupt
SERIAL_READ:
if serial_input_port == "A"
    jp RC2014_SerialSIO2A_InputChar_T2
else
    jp RC2014_SerialSIO2B_InputChar_T2
endif
    
;====================================
;Wait for a char from the serial port and return it
;Out: A=the character
;   Flags corrupt
SERIAL_WAIT:
    call SERIAL_READ
    ret nz
    jr SERIAL_WAIT
    
;===================================
;Send and escape code prefix: ESC [
;Out: AF corrupt
TERM_ESC_PREFIX:
    ld a,27
    call SERIAL_OUT
    ld a,'['
    jp SERIAL_OUT
    
;====================================
;Sends a single character ESCape sequence for the char in A
;i.e sends 'ESC[' followed by  A (as a char)
;Out: AF corrupt
TERM_ESC_A:
    push af
    call TERM_ESC_PREFIX
    pop af
    jp SERIAL_OUT
    
;======================================
;Sends a two character ESCape sequence for the sequence in DE
;i.e sends a 'ESC[' followed the the byte in D and then the byte in E (as chars)
;Out: All registers preserved
TERM_ESC_DE:
    push af
    ld a,d
    call term_esc_a
    ld a,e
    call SERIAL_OUT
    pop af
    ret
    
;========================================
;Sends an ESCape string - ESC[ - followed by the ASCIIZ string pointed
;at by HL
;Out: HL points to the last byte of the string (the zero)
;   AF corrupt
TERM_ESC_ASCIIZ:
    call TERM_ESC_PREFIX

term_esc_asciiz_loop:
    ld a,(hl)
    and a
    ret z
    
    call SERIAL_OUT
    inc hl
    jr term_esc_asciiz_loop
    
;=======================================
;Send value in E as decimal string (max two digits)
;Note that this routine does not send an escape prefix.
;It is intended for sending the parameters for other commands.
;Out: AF corrupt.
TERM_DECIMAL:
    push de
    push hl
    
    ld d,0         ;Divide A by 10
    ld h,d
    ld l,e
    add hl,hl
    add hl,de
    add hl,hl
    add hl,hl
    add hl,de
    add hl,hl      ;H = A/10
     
    ld a,h         ;Test for single digit number
    or a
    jr z,single_digit
     
    add a,'0'      ;Send first digit
    call SERIAL_OUT
     
single_digit:
    ld a,h          ;Multiply result by 10
    rla
    rla
    add a,h
    rla             ;A = result * 10
    
    sub a,e         ;Subtract initial value to get (-modulus)
    neg             ;A=modulus
    
    add a,'0'       ;To ASCII
    call SERIAL_OUT   ;Send second digit
    
    pop hl
    pop de
    ret

;=======================================
;Sends an ESC [ <row> ; <column> H cursor position command
;The cursor position is in the HL register pair,
; L=Row value
; H=Column value
;Both values are zero based (physical co-ordinates)
;Out: All registers preserved   
TERM_CURSORPOS:
    push af
    push de
    push hl
    call TERM_ESC_PREFIX
     
    ld e,l         ;E=row
    inc e
    call TERM_DECIMAL
     
    ld a,';'
    call SERIAL_OUT
     
    ld e,h         ;E=column
    inc e
    call TERM_DECIMAL
     
    ld a,'H'
    call SERIAL_OUT
     
    pop hl
    pop de
    pop af
    ret