;Driver for RC2014 8x8 Matrix display module by Sheila Dixon
;See - https://peacockmedia.software/RC2014/8x8_matrix/
;
;Install by calling &a000
;
;Commands
;|MAT.ON
;|MAT.OFF
;|MAT.SET,<x>,<y>
;|MAT.CLEAR,<x>,<y>
;|MAT.ROW,<y>,<data>
;|MAT.GET,<x>,<y>,@<outvar:integer>
;|MAT.GETROW,<x>,<y>,@<outvar:integer>

kl_log_ext equ $bcd1

;Install RSX
org $8000       
    ld hl,work_space
    ld bc,jump_table
    jp kl_log_ext

;Workspace for firmware
work_space:
    db 0,0,0,0
    
;RSX jump table
jump_table
    dw name_table
    
    jp MAT_SHOW
    jp MAT_ON
    jp MAT_OFF
    jp MAT_SET
    jp MAT_CLEAR
    jp MAT_ROW
    jp MAT_GET
    jp MAT_GETROW
    
    ;...More
    
;RSX name table
name_table:
    db "MAT.SHO","W"+$80
    db "MAT.O","N"+$80
    db "MAT.OF","F"+$80
    db "MAT.SE","T"+$80
    db "MAT.CLEA","R"+$80
    db "MAT.RO","W"+$80
    db "MAT.GE","T"+$80
    db "MAT.GETRO","W"+$80
;    db "MAT.O","N"+&80
;    db "MAT.O","N"+&80
;    db "MAT.O","N"+&80
;    db "MAT.O","N"+&80
;    db "MAT.O","N"+&80
    db 0
    
    
;Each bit in these values equates to a single row or column
row_select_port equ 0      ;Data sent to the row_data_port will be shown on any rows activated by the row_select_port
row_data_port equ 2

;8 rows of pixel data
pixel_data:
    db 128,64,32,16,8,4,2,1     ;Sample data
    
;Display the current pixel data
MAT_SHOW:
;We cycle through each row in turn. First we send the data for the pixels to be displayed on this
;row to the row_port. The we activate the row via the col_port
    ld hl,pixel_data
    ld c,1                      ;Row to activate
    
show_loop:
    xor a
    out (row_select_port),a     ;Deactivate all rows, to stop spurious pixels showing
    ld a,(hl)                   ;Get data for row
    out (row_data_port),a       ;Output row data
    ld a,c
    out (row_select_port),a     ;Activate row
    
    inc hl                      ;Next row
    rla                        
    ld c,a
    jr nc,show_loop             ;Loop until all shown
    
    xor a
    out (row_select_port),a
    
    jr show_loop
    
    ret

    
    
MAT_ON:
    ret
    
MAT_OFF:
    ret
    
MAT_SET:
    ret
    
MAT_CLEAR:
    ret
    
MAT_ROW:
    ret
    
MAT_GET:
    ret
    
MAT_GETROW
    ret