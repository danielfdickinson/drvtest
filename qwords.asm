;******************************************************************************
; $Id: qwords.asm,v 1.1 2004/02/18 15:02:44 dfd Exp dfd $
;
; 64-bit integer arithmetic
;
; ChangeLog
;
; $Log: qwords.asm,v $
; Revision 1.1  2004/02/18 15:02:44  dfd
; Initial revision
;
; Revision 1.1  2004/02/18 15:00:15  dfd
; Initial revision
;
;******************************************************************************

%ifndef __QWORDS	; Only include file once
%define __QWORDS

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
    ret
.subtract
    sub [remainder_low], ebx
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

%endif
