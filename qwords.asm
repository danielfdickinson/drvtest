;******************************************************************************
; $Id: qwords.asm,v 1.1 2004/02/18 15:00:15 dfd Exp dfd $
;
; 64-bit integer arithmetic
;
; ChangeLog
;
; $Log: qwords.asm,v $
; Revision 1.1  2004/02/18 15:00:15  dfd
; Initial revision
;
;******************************************************************************

section .text

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
    push eax
    push ecx
    mov al, 0			; Zero out result and remainder
    mov cx, 8
    mov di, result
    rep stosb
    mov di, remainder
    mov cx, 8
    rep stosb
    pop eax
    pop ecx
    mov [bitnum], byte NUM_BITS
    call .mainloop
    mov edx, [result_high]
    mov eax, [result_low]
    mov ecx, [remainder_high]
    mov ebx, [remainder_low]
    ret

.mainloop
    call .divide
    dec byte [bitnum]
    jne .mainloop
    clc
    ret

.divide
    clc
    rcl eax, 1
    rcl edx, 1
    clc
    rcl dword [remainder_low], 1
    rcl dword [remainder_high], 1
    cmp [remainder_high], ecx
    call .not_sure
    jnc .answer_bit
    call .subtract
.answer_bit
    rcl dword [result_low], 1
    rcl dword [result_high], 1
    ret
.not_sure
    cmp [remainder_low], ebx
    jnc .subtract
    call .answer_bit
.subtract
    jnc .do_sub
    call .answer_bit
.do_sub:
    stc
    sbb [remainder_low], ebx
    sbb [remainder_high], ecx
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
