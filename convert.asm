;---------------------
; Get number as string
; IN: ES:DI = where to store number string
; EDX:EAX =  value to print, EBX = number base, DS = data seg
; OUT: [ES:DI] = number as string (ASCIIZ)
;
number_string:
	push cx
	push di
	push si

	XOR     CX,CX              ; Counter for the amount of digits
.div:  			            ; by division & Modulo determine
	DIV     EBX                ; the digits backwards ...
	PUSH    DX                 ; ... and put them on the stack
	xor     edx, edx
	AND     EAX,EAX            ; Something left somewhere?
LOOPNZ  .div
	NEG     CX                ; Gives the number of digits

.stringify
	POP     AX	       	; get the single digit from stack (will pop
				; in correct order)
	cmp     ax, 10
	jae     .letter_digit
	ADD     AL, '0'          	
	stosb		 	; and store in string
LOOP .stringify
	jmp 	.add_null
.letter_digit
	sub 	al, 10
	add 	al, 'A'
        stosb
loop    .stringify
.add_null
	mov al, 0
        stosb
        pop si
        pop di
        pop cx
        ret
