; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  RC2014                                               **
; **  Interface: Serial SIO/2                                         **
; **********************************************************************

; This module is the driver for Z80 SIO/2 serial modules. It supports
; both Grant's original and Spencer's official addresing schemes.
;
; WARNING: the official SIO/2 module is not compatible with Grant
; Searle's original design (later used by Dr. S Baker's module).
; Addresses used:
; Original: SIOA-C=0x82, SIOA-D=0x80, SIOB-C=0x83, SIOB-D=0x81
; Official: SIOA-C=0x80, SIOA-D=0x81, SIOB-C=0x82, SIOB-D=0x83
; Address signals:
; Original: SIO C/D line = A1,  SIO B/A line = A0
; Official: SIO C/D line = /A0, SIO B/A line = A1
;
; RC2014 standard addresses for Grant's original SIO/2: (type 1)
; 0x82   Channel A control registers (read and write)
; 0x80   Channel A data registers (read and write)
; 0x83   Channel B control registers (read and write)
; 0x81   Channel B data registers (read and write)
;
; RC2014 standard addresses for Spencer's official SIO/2: (type 2)
; 0x80   Channel A control registers (read and write)
; 0x81   Channel A data registers (read and write)
; 0x82   Channel B control registers (read and write)
; 0x83   Channel B data registers (read and write)
;
; Too complex to reproduce technical info here. See SIO datasheet

; Base address for SIO externally defined. eg:
kSIO2:     EQU 0x80           ;Base address of SIO/2 chip

; SIO/2 type 1 registers derived from base address (above)
kSIOAConT1: EQU kSIO2+2        ;I/O address of control register A
kSIOADatT1: EQU kSIO2+0        ;I/O address of data register A
kSIOBConT1: EQU kSIO2+3        ;I/O address of control register B
kSIOBDatT1: EQU kSIO2+1        ;I/O address of data register B
;
; SIO/2 type 2 registers derived from base address (above)
kSIOAConT2: EQU kSIO2+0        ;I/O address of control register A
kSIOADatT2: EQU kSIO2+1        ;I/O address of data register A
kSIOBConT2: EQU kSIO2+2        ;I/O address of control register B
kSIOBDatT2: EQU kSIO2+3        ;I/O address of data register B

; Status (control) register bit numbers
kSIORxRdy:  EQU 0              ;Receive data available bit number
kSIOTxRdy:  EQU 2              ;Transmit data empty bit number

; Device detection, test 1
; This test just reads from the devices' status (control) register
; and looks for register bits in known states:
; CTS input bit = high
; DCD input bit = high
; Transmit data register empty bit = high
kSIOMask1:  EQU  0b00101100    ;Mask for known bits in control reg
kSIOTest1:  EQU  0b00101100    ;Test value following masking


;            .CODE

; **********************************************************************
; **  Type 1 (Grant's original addressing scheme)                     **
; **********************************************************************


; RC2014 type 1 serial SIO/2 initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
RC2014_SerialSIO2_Initialise_T1:
; First look to see if the device is present
            IN   A,(kSIOAConT1) ;Read status (control) register A
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
            IN   A,(kSIOBConT1) ;Read status (control) register B
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
; Device present, so initialise A
            LD   C,kSIOAConT1   ;SIO/2 channel A control port
            CALL RC2014_SerialSIO2_IniSend
            LD   C,kSIOBConT1   ;SIO/2 channel B control port
            JP   RC2014_SerialSIO2_IniSend


; RC2014 type 1 serial SIO/2 channel A & B input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if character input
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
RC2014_SerialSIO2A_InputChar_T1:
            IN   A,(kSIOAConT1) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOADatT1) ;Read data byte
            RET
RC2014_SerialSIO2B_InputChar_T1:
            IN   A,(kSIOBConT1) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOBDatT1) ;Read data byte
            RET


; RC2014 type 1 serial SIO/2 channel A & B output character
;   On entry: A = Character to be output to the device
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
RC2014_SerialSIO2A_OutputChar_T1:
            PUSH BC
            LD   C,kSIOAConT1   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOADatT1),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET
RC2014_SerialSIO2B_OutputChar_T1:
            PUSH BC
            LD   C,kSIOBConT1   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOBDatT1),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET


; **********************************************************************
; **  Type 2 (Spencer's original addressing scheme)                   **
; **********************************************************************

; RC2014 type 2 serial SIO/2 initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
RC2014_SerialSIO2_Initialise_T2:
; First look to see if the device is present
            IN   A,(kSIOAConT2) ;Read status (control) register A
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
            IN   A,(kSIOBConT2) ;Read status (control) register B
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
; Device present, so initialise 
            LD   C,kSIOAConT2   ;SIO/2 channel A control port
            CALL RC2014_SerialSIO2_IniSend
            LD   C,kSIOBConT2   ;SIO/2 channel B control port
            JP   RC2014_SerialSIO2_IniSend


; RC2014 type 2 serial SIO/2 channel A & B input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if character input
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
RC2014_SerialSIO2A_InputChar_T2:
            IN   A,(kSIOAConT2) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOADatT2) ;Read data byte
            RET
RC2014_SerialSIO2B_InputChar_T2:
            IN   A,(kSIOBConT2) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOBDatT2) ;Read data byte
            RET


; RC2014 type 2 serial SIO/2 channel A & B output character
;   On entry: A = Character to be output to the device
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
RC2014_SerialSIO2A_OutputChar_T2:
            PUSH BC
            LD   C,kSIOAConT2   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOADatT2),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET
RC2014_SerialSIO2B_OutputChar_T2:
            PUSH BC
            LD   C,kSIOBConT2   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOBDatT2),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET


; **********************************************************************
; **  Private functions                                               **
; **********************************************************************


; RC2014 serial SIO/2 write initialisation data 
;   On entry: C = Address of SIO control register
;   On exit:  DE IX IY I AF' BC' DE' HL' preserved
; Send initialisation data to specied control register
RC2014_SerialSIO2_IniSend:
            LD   HL,SIOIni     ;Point to initialisation data
            LD   B,SIOIniEnd-SIOIni ;Length of ini data
            OTIR                ;Write data to output port C
            XOR  A              ;Return Z flag as device found
            RET
; SIO channel initialisation data
SIOIni:    DB  0b00011000     ; Wr0 Channel reset
;           DB  0b00000010     ; Wr0 Pointer R2
;           DB  0x00           ; Wr2 Int vector
            DB  0b00010100     ; Wr0 Pointer R4 + reset ex st int
            DB  0b11000100     ; Wr4 /64, async mode, no parity
            DB  0b00000011     ; Wr0 Pointer R3
            DB  0b11000001     ; Wr3 Receive enable, 8 bit 
            DB  0b00000101     ; Wr0 Pointer R5
;           DB  0b01101000     ; Wr5 Transmit enable, 8 bit 
            DB  0b11101010     ; Wr5 Transmit enable, 8 bit, flow ctrl
            DB  0b00010001     ; Wr0 Pointer R1 + reset ex st int
            DB  0b00000000     ; Wr1 No Tx interrupts
SIOIniEnd:


; **********************************************************************
; **  End of driver: RC2014, Serial SIO/2                             **
; **********************************************************************









