org 100h

VIDEO_BASE_SEG      EQU 0b800h
SCREEN_COLOUR	    EQU 71h

start:
;   mov bp, sp				; Stack stack pointer
   mov bp, end_of_bss + STACK_SIZE	; Set new top of stack
   sub bp, 2				; And set stack to indicate 4 bytes
					; used (return offset + DOS 2 bytes)
   mov si, sp
   sub si, 2
   mov eax, [si]			; Copy this function's return offset +
;   mov si, [02h]
;   dec di
;   dec di
   mov [bp], eax			; two bytes put on stack by DOS
   mov sp, bp
    mov [cur_col], byte 0
    mov [cur_row], byte 0
    mov ax, cs
    mov es, ax
    mov ds, ax
    mov di, print_buffer
    xor edx, edx
    xor eax, eax
    mov ax, cs
    mov ebx, 16
    call print_number
    inc byte [cur_col]
    mov ax, ss
    mov ebx, 16
    call print_number
    inc byte [cur_col]
    mov ax, sp
    mov ebx, 16
    call print_number
    inc byte [cur_col]
    xor edx, edx
    mov eax, 100
    mov ebx, 10
    call print_number
    xor edx, edx
    mov eax, 100
    xor ecx, ecx
    mov ebx, 10
;    mov di, print_buffer
    inc byte [cur_col]
    call qword_divide
    mov ebx, 10
    call print_number
    mov ah, 04Ch
    mov al, 00
    int 21h
  

;---------------------
; Get number as string (base in ebx, digits 0-9 and A-Z = base 2 to 36)
; IN: ES:DI = where to store number string
; EDX:EAX =  value to print, EBX = number base, DS = data seg
; OUT: [ES:DI] = number as string (ASCIIZ)
;
number_string:
	push cx
	push di
	push si
;        push cs
;       pop ds
        mov [base], ebx
	xor si, si                 ; Counter for the amount of digits
.div:
	inc si			   ; We're in the digit loop so digit_count++
        xor ecx, ecx		   ; ECX:EBX = 0:Base to divide by
;        call qword_divide          ;    Remainder gives digits backwards      
        div ebx
	push dx                    ;    so put them on the stack
  				   ;   (we can use just bx because digit 0-126)
        mov ebx, [base]            ; Bring back the denominator
        xor edx, edx               ; ** DEBUG **
	and eax, eax               ; Anything left to convert to digits?
        jnz .div		   ;   Yes, loop
        and edx, edx               ; What about in the high dword?
        jnz .div                   ;   Yes, loop

.num_digits
	mov cx, si		; we don't need ecx so use cx for loop
.stringify
	pop ax	    	   	; get the single digit from stack (will pop
				; in correct order)
	cmp     ax, 10
	jae     .letter_digit
	ADD     AL, '0'          	
	stosb		 	; and store in string
loop .stringify
	jmp 	.add_null
.letter_digit
	add 	al, 'A'-10
        stosb
loop    .stringify
.add_null
	mov al, 0
        stosb
        pop si
        pop di
        pop cx
        ret

section .bss

base	resd 1

section .text

%macro prtNum 1
    pushf
    push edx 
    push eax 
    push ecx 
    push ebx
    xor edx, edx
    mov ebx, 2
    mov eax, %1
    call print_number
    inc byte [cur_col]
    pop ebx 
    pop ecx 
    pop eax 
    pop edx
    popf
%endmacro

;--------------------------
; Divide a qword by a qword
;
; IN: 
;     EDX:EAX =  numerator
;     ECX:EBX =  denominator
;
; OUT: Carry set = divide by zero or one error
;     EDX:EAX = Result
;     ECX:EBX = Remainder
;
qword_divide:
    push di
    push ecx
    push eax

    mov al, 0			; Zero out result and remainder
    mov cx, 8
    mov di, result
    rep stosb
    mov di, remainder
    mov cx, 8
    rep stosb
    pop eax
    pop ecx
    pop di
    mov [bitnum], byte NUM_BITS
    call .mainloop
    mov edx, [result_high]
    mov eax, [result_low]
    mov ecx, [remainder_high]
    mov ebx, [remainder_low]
    ret

.mainloop
    clc
    rcl eax, 1
    rcl edx, 1
    rcl dword [remainder_low], 1
    rcl dword [remainder_high], 1
    prtNum [remainder_low]
    cmp ecx, [remainder_high]
    je .not_sure
    jb .rem_contains_den
    call .answer_bit
.main_cont
    dec byte [bitnum]
    jne .mainloop
    clc
    ret

.rem_contains_den
    stc
    call .answer_bit
    call .subtract
    jmp .main_cont
  
.not_sure
    cmp ebx, [remainder_low]
    jbe .rem_contains_den
    call .answer_bit
    jmp .main_cont

.answer_bit
    rcl dword [result_low], 1
    rcl dword [result_high], 1
    prtNum [result_low]
    ret
.subtract
    sub [remainder_low], ebx
    sbb [remainder_high], ecx
    prtNum [remainder_low]
    ret

section .bss

;----------
; Variables
;
result:
result_low	resd 1
result_high	resd 1

remainder:
remainder_low	resd 1
remainder_high	resd 1

bitnum 	        resb 1

; Constants
NUM_BITS	EQU	64	; Number of bits we know how to deal with

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
	mov ds, ax		; code, data, and bss segs are the same
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
cur_col			resb 1
cur_row			resb 1

end_of_bss

STACK_SIZE EQU 2048
