; **********************************************************************
; **  Hex file loader                           by Stephen C Cousins  **
; **********************************************************************

; This module loads an Intel Hex file from the current input device.
;
; An Intel Hex file is a text file where each line is a record.
;
; A record starts with a colon (':') and ends with CR and/or LF.
;
; The next two characters form a hex byte which is the number of data
; bytes in the record.
;
; The next four characters form a hex word which is the start address 
; for the record's data bytes. High byte first.
;
; The next two characters form a hex byte which describes the type of
; record. 0x00 is a normal data record. 0x01 is an end of file marker.
;
; Then follows the specified number of data bytes, each written as two 
; character hex number.
;
; Finally there is a checksum byte in the form of a two character hex
; number. 
;
; To test the checksum simply add up all bytes in the record, including
; the checksum (but not the colon), and test to see if it is zero.
;
; The checksum is calculated by adding together all bytes in the record
; except the checksum byte and the colon character, ANDing with 0xFF 
; and then subtracting from 0x100. 
;
; Example record:
;   :0300300002337A1E 
; Record Length: 03 (3 bytes of data)
; Address: 0030 (the 3 bytes will be stored at 0030, 0031, and 0032)
; Record Type: 00 (normal data)
; Data: 02, 33, 7A
; Checksum: 1E (03 + 00 + 30 + 00 + 02 + 33 + 7A = E2, 100 - E2 = 1E)
;
; The last line of the file is an end marker with 00 data bytes and 
; record type 01, and so is:
;   :00000001FF
;
; Test file: (loads data 0x03 0x02 0x01 to address 0x4000)
;   :03400000030201B7
;   :00000001FF
;
; Public functions provided
;   HexLoad               Load hex file from the current console input


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

;            .CODE

kSpace equ ' '
kColon equ ':'

MsgReady:
    defb "Success",13,10,0
MsgFileErr:
    defb "CRC Error",13,10,0

; HexLoader: Load an intel hex file from the current console input
;   On entry: No parameters required
;   On exit:  IX IY I AF' BC' DE' HL' preserved
HexLoad:    LD   C,0            ;Clear checksum of this whole file
            jr HexLoad_First    ;(Colon has been read by the terminal)
HexLoad_Line:      CALL SERIAL_WAIT  ;Get first character in record/line
            CP   kSpace         ;Control character?
            JR   C,HexLoad_Line        ;Yes, so discard it
            CP   kColon         ;Colon?
            RET  NZ             ;No, so return with this character
;           LD   C,0            ;Clear checksum for this line only
HexLoad_First:
; Get number of data bytes in this record
            CALL HexGetByte     ;Get number of data bytes
            LD   B,A            ;Store number of data bytes in record
            ADD  A,C            ;Add to checksum
            LD   C,A
; Get start address for this record
            CALL HexGetByte     ;Get address hi byte
            LD   D,A            ;Store address hi byte
            ADD  A,C            ;Add to checksum
            LD   C,A
            CALL HexGetByte     ;Get address lo byte
            LD   E,A            ;Store address lo byte
            ADD  A,C            ;Add to checksum
            LD   C,A
; Get record type
            CALL HexGetByte     ;Get record type
            LD   H,A            ;Store record type
            ADD  A,C            ;Add to checksum
            LD   C,A
; Input any data bytes in this record
            LD   A,B            ;Get number of bytes in record
            OR   A              ;Zero?
            JR   Z,HexLoad_Check       ;Yes, so skip..
HexLoad_Data:      CALL HexGetByte     ;Get data byte
            LD   (DE),A         ;Store data byte in memory
            INC  DE             ;Point to next memory location
            ADD  A,C            ;Add to checksum
            LD   C,A
            DJNZ HexLoad_Data
; Get checksum byte for this record
HexLoad_Check:     CALL HexGetByte     ;Get checksum byte
            ADD  A,C            ;Add to checksum
            LD   C,A
; Should now test checksum for this line, but instead keep a checksum 
; for the whole file and test only at the end. This avoids having to 
; store a failure flag (no registers left) whilst still allowing this
; function to flush all lines of the file.
;Test for end of file
            LD   A,H            ;Get record type
            CP   1              ;End of file?
            JR   NZ,HexLoad_Line       ;No, so repeat for next record
; End of file so test checksum
            LD   A,C            ;Get checksum
            OR   A              ;It should be zero?
            LD   hl,MsgReady    ;Prepare for checksum ok message
            JR   Z,HexLoad_Result      ;Skip if checksum ok
            LD   hl,MsgFileErr   ;File error message number
HexLoad_Result:    CALL display_a_null_terminated_string   ;Output message
;            XOR  A              ;Return null character
;            LD   A,kNewLine
;            LD   A,kReturn
            RET


; **********************************************************************
; **  Private functions                                               **
; **********************************************************************

; HexLoader: Get byte from two hex characters from current console input
;   On entry: No parameters required
;   On exit:  A = Bytes received
;             BC DE H IX IY I AF' BC' DE' HL' preserved
HexGetByte: CALL SERIAL_WAIT      ;Get character from input device
            CALL ConvertCharToNumber
            RLCA
            RLCA
            RLCA
            RLCA
            LD   L,A            ;Store result hi nibble
            CALL SERIAL_WAIT      ;Get character from input device
            CALL ConvertCharToNumber
            OR   L            ;Get result byte
            RET


; **********************************************************************
; **  End of Hex file loader module                                   **
; **********************************************************************

; Utility: Convert character to numberic value
;   On entry: A = ASCII character (0-9 or A-F)
;   On exit:  If character is a valid hex digit:
;               A = Numberic value (0 to 15) and Z flagged
;             If character is not a valid hex digit:
;               A = 0xFF and NZ flagged
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
;             Interrupts not enabled
ConvertCharToNumber:
            CALL ConvertCharToUCase
            CP   '0'            ;Character < '0'?
            JR   C,CCN_Bad         ;Yes, so no hex character
            CP   '9'+1          ;Character <= '9'?
            JR   C,CCN_OK          ;Yes, got hex character
            CP   'A'            ;Character < 'A'
            JR   C,CCN_Bad         ;Yes, so not hex character
            CP   'F'+1          ;Character <= 'F'
            JR   C,CCN_OK          ;No, not hex
; Character is not a hex digit so return 
CCN_Bad:       LD   A,0xFF         ;Return status: not hex character
            OR   A              ;  A = 0xFF and NZ flagged
            RET
; Character is a hex digit so adjust from ASCII to number
CCN_OK:        SUB  '0'            ;Subtract '0'
            CP   0x0A           ;Number < 10 ?
            JR   C,CCN_Finished    ;Yes, so finished
            SUB  0x07           ;Adjust for 'A' to 'F'
CCN_Finished:  CP   A              ;Return A = number (0 to 15) and Z flagged to
            RET                 ;  indicate character is a valid hex digital


; Utility: Convert character to upper case
;   On entry: A = Character in either case
;   On exit:  A = Character in upper case
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
ConvertCharToUCase:
            CP   'a'            ;Character less than 'a'?
            RET  C              ;Yes, so finished
            CP   'z'+1          ;Character greater than 'z'?
            RET  NC             ;Yes, so finished
            SUB  'a'-'A'        ;Convert case
            RET



