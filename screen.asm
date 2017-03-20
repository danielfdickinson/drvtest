;******************************************************************************
; Screen operations
;******************************************************************************

%ifndef __SCREEN_ASM
%define __SCREEN_ASM

section .text

;-------------------
; Initialize display
;
init_display:
   mov ah, 00h			; Set video mode
   mov al, 03h			;   To 80x25 colour starting at b800
   int 10h			;

   mov ah, 05h			; Set current page 
   mov al, 00h			;    To page 0
   int 10h

   call clear_screen		; Clear the screen
   call set_cursor_position	

;--------------------
; Set cursor position
;
; IN: [cur_row] = row (0 based), [cur_col] = column (0 based)
; OUT: None
;
set_cursor_position
   push ax
   push dx
   push bx

   mov ah, 02h		; Set cursor position
   mov bh, 00h		;    For page 0
   mov dh, [cur_row]	;    Row,
   mov dl, [cur_col]	;    Column
   int 10h

   pop bx
   pop ax
   pop dx

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
   mov cx, 79  			; line length - 1
   xor ax, ax
   mov al, [cur_col]
   sub cx, ax			;    amount that s/b spaces
   mov ah, SCREEN_COLOUR	; attribute
   mov al, ' '			;    clear screen (space)
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

;-------------
; Print Spaces
;
; IN: cx = space count, cur_row, cur_col = row, col
; OUT: cur_row, cur_col = last printed position
;
print_spaces:
      push es		; We mess with data segments, so save them
      push ds
      push ax  		; This routine is used too often to not save regs
      push bx
      push dx
      push di
      push si

      mov ax, VIDEO_BASE_SEG	; Direct video memory writes
      mov es, ax
      xor ax, ax
      xor bx, bx
      xor dx, dx
      mov al, [cur_col]		; current column (zero-based)
      mov dx, ax
      shl dx, 1			; * 2 (char/att pair)
      mov al, [cur_row]		; current row (zero-based)
      mov bl, 160		; * 80 * 2 (char/att pair) = linear screen pos
      mul bl
      add dx, ax	; di = offset into video memory for current row+col
      mov di, dx
      mov si, [string_loc]	; source is at [string_loc]
      xor ax, ax
      mov ah, SCREEN_COLOUR	; attribute
      mov al, ' '
      mov bx, cx
      rep stosw			; store in screen memory

      xor ax, ax		; Calculate # of rows 
      xor dx, dx
      mov ax, bx		; # rows = 
      mov bx, 80		;    spaces / 80
      div bx      
      mov cl, [cur_row]		; cur_row = 
      add cx, ax		;    cur_row + #row
      mov [cur_row], cl
      add dx, [cur_col]		; cur_col = cur_col + remainder
      mov [cur_col], dl		;
.done2
      pop si   		; This routine is used too often to not save regs
      pop di
      pop dx
      pop bx
      pop ax
      pop ds		; We messed with data segments, so restore them
      pop es
      ret


%include "convert.asm"

section .text

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

;******************************************************************************

section .data
;----------------------
; Initialized Variables
;----------------------
cur_row				db 0
cur_col				db 0

section .bss

;----------
; Variables
;----------
string_loc		resw 1		; Pointer to string to print
print_buffer		resb 161	; Buffer for numbers to print

;-------
; Macros
;-------

%macro print_debug_num_32 2
    pushf
    push eax
    push ebx
    push edx
    push ecx
    push si
    push di
    mov eax, %1
    mov ebx, %2
    call print_number
    pop di
    pop si
    pop ecx
    pop edx
    pop ebx
    pop eax
    popf
%endmacro

%endif ; __SCREEN_ASM
