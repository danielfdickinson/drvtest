;******************************************************************************
; Conversion routines : 
;
; number_string: Integer to string in a base from 2 to 36 (digits 0-9 and A-Z)
; Requires qword_divide
;******************************************************************************

%ifndef __CONVERT
%define __CONVERT

%include "qwords.asm"

section .text

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
;        pop ds
        mov [base], ebx
	xor si, si                 ; Counter for the amount of digits
.div:
	inc si			   ; We're in the digit loop so digit_count++
        xor ecx, ecx		   ; ECX:EBX = 0:Base to divide by
        call qword_divide          ;    Remainders gives digits backwards      
;        div ebx
	push bx                    ;    so put them on the stack
  				   ;   (we can use just bx because digit 0-126)
        mov ebx, [base]            ; Bring back the denominator
;        xor edx, edx
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

%endif
