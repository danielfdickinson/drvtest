;******************************************************************************
; Screen operations
;******************************************************************************

section .text

;-------------
; Clear screen
; IN: ah = attribute
; OUT: ax, di, cx destroyed
;
clear_screen:
   push es			; We mess with es so save it
   mov ax, VIDEO_BASE_SEG	; Direct video memory writes
   mov es, ax
   xor di, di			; offset 0 (row, col) = (0, 0)
   mov ah, SCREEN_COLOUR	;
   mov al, ' '
   mov cx, (80 * 25)		; # characters on screen
   rep stosw
   pop es			; We messed with es so restore it
   ret

;---------------------
; Clear to end of line
; IN: ah = attribute
; OUT: none
;
clear_eol

   push es			; Save regs
   push ax
   push bx
   push cx
   push di

   mov ax, VIDEO_BASE_SEG	; Video mem base
   mov es, ax
   xor ax, ax
   mov al, [cur_row]		; current row
   mov bl, 160		; * 80 * 2 = offset into vid mem for current row
   mul bl
   xor bx, bx
   mov bl, [cur_col]		; current col
   shl bx, 1			; * 2 = offset for cur col
   add ax, bx			; row_offset + col_offset = final offset
   mov di, ax     		; di = offset
   mov ah, SCREEN_COLOUR	; attribute
   mov al, ' '			;    clear screen (space)
   mov cx, 80  			; line length
   sub cx, [cur_col]		;    amount that s/b spaces
   rep stosw			; do it

   pop di			; Restore regs
   pop cx
   pop bx
   pop ax
   pop es

	ret

;-------------
; Print string
; IN: cur_row, cur_col = row, col,
;     string_loc = offset in data seg of string to print
; OUT: cur_row, cur_col = last printed position
;
print_string
      push es		; We mess with data segments, so save them
      push ds
      push ax  		; This routine is used too often to not save regs
      push cx
      push bx
      push dx
      push di
      push si

      mov ax, VIDEO_BASE_SEG	; Direct video memory writes
      mov es, ax
      xor ax, ax
      xor bx, bx
      mov al, [cur_col]		; current column (zero-based)
      mov cx, ax
      shl cx, 1			; * 2 (char/att pair)
      mov al, [cur_row]		; current row (zero-based)
      mov bl, 160		; * 80 * 2 (char/att pair) = linear screen pos
      mul bl
      add cx, ax	; di = offset into video memory for current row+col
      mov di, cx
      mov si, [string_loc]	; source is at [string_loc]
      xor ax, ax
      mov ah, SCREEN_COLOUR	; attribute
      lodsb			; first character
.loop
      stosw			; store in screen memory
      lodsb			; get next character
      cmp al, 0			; 0 terminates string
      jz .done
      inc byte [cur_col]	; keep track of where we are
      cmp [cur_col], byte 80	; if next col is < 80
      jb .loop			;    loop
      inc byte [cur_row]  	; else row++	(we don't worry about overflow)
      mov [cur_col], byte 0	;	  col = 0
      jmp .loop

.done
      inc byte [cur_col]	; keep track of where we are
      cmp [cur_col], byte 80	; if next col is < 80
      jb .done2			;    loop
     inc byte [cur_row]	  	; else row++	(we don't worry about overflow)
      mov [cur_col], byte 0	;	  col = 0
.done2
      pop si   		; This routine is used too often to not save regs
      pop di
      pop dx
      pop bx
      pop cx
      pop ax
      pop ds		; We messed with data segments, so restore them
      pop es
      ret

%include "convert.asm"

;-------------
; Print number
; IN edx:eax value to print, es, ds = data seg, EBX = BASE
; cur_row, cur_col = start row, col
; print_buffer = storage for ASCII string (zero terminated)
;
print_number
	push cx
	push di
	push si

        push ax
        mov ax, cs
	mov es, ax		; code, data, and bss segs are the same
        pop ax
        mov di, print_buffer	; es:di = offset of location to store string
        call number_string
        mov [string_loc], word print_buffer
        call print_string

        pop si
        pop di
	pop cx
	RET

section .bss

;----------
; Variables
;----------
string_loc		resw 1		; Pointer to string to print
print_buffer		resb 161	; Buffer for numbers to print

