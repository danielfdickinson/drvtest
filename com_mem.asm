;----------------------------------------------
; Initialize end of available memory for a .COM
;
; 
init_com_alloc
   mov ax, [02h]		; Offset 02h in PSP is seg of first byte past
				;    memory allocated to .COM
   mov [first_avail_byte], ax	; Store that info
   ret				; and return

;------------------------------
; Record memory usage in a .COM
;
; IN: 
;    BX = requested size in paragraphs
; OUT: 
;    Success
;        Carry clear: 
;        AX = Segment allocated
;    Failure
;        Carry set
;        AX = Error code
;        BX = Segment that failed
;
allocate_segment
   mov ax, [first_avail_byte] 	; Seg of first byte not available
   sub ax, bx			; Seg - desired = allocated seg
   jc .alloc_err1   
   mov bx, cs
   cmp ax, bx 			; If code+data+bss seg >= alloc_seg we 
   ja .alloc_ok			;   would overlap
.alloc_err2
   mov bx, ax			; Seg we tried to allocate
   mov ax, 02h			; Error code 02h
   stc
   jmp .exit
.alloc_err1
   mov bx, ax			; Seg we wanted to allocate
   mov ax, 01h			; Error code 01h
   stc
   jmp .exit

.alloc_ok
   stosw
   mov [first_avail_byte], ax
   clc
.exit
   ret


;--------------------------------------------
; Get error string for .COM memory allocation
;
; IN: AX = error code
;     BX = returned segment (seg that failed)
;     ES:DI = where to store error message string
;
; OUT:  [ES:DI] = error message string
;
get_com_mem_error_string:

; Error code 01h
    cmp ax, 01h
    jnz .com_mem_full
.no_avail_mem
    mov si, msg_alloc_err_no_avail
    mov cx, msg_alloc_err_no_avail_end - msg_alloc_err_no_avail
    rep movsb			; Copy string to buffer
    mov ax, cs			; In .com code+data+bss segs the same
    mov es, ax
    mov [di], byte ' '
    inc di
    xor edx, edx
    xor eax, eax
    mov ax, bx
    mov ebx, 16
    call number_string		; convert last avail seg to hex
    jmp .done

; Error code 02h
    cmp ax, 02h
    jnz .err_err
.com_mem_full	
    push bx
    mov si, msg_alloc_err_com_full
    mov cx, msg_alloc_err_com_full_end - msg_alloc_err_com_full
    rep movsb				; Copy string to buffer
    mov ax, cs				; code, data, bss segs the same
    mov es, ax				; and print_number needs ES:DI
    mov [di], byte ' '
    inc di
    xor edx, edx
    xor eax, eax
    mov ax, cs				; First we print program seg
    mov ebx, 16				;   in hex
    call number_string
    mov [di - 1], byte ' '		; [DI] = 0 (string terminator)
    inc di
    xor edx, edx
    xor eax, eax
    pop ax				; Then we print last avail seg
    mov ebx, 16				;   in hex
    call number_string
    jmp .done    
.err_err
    mov cx, msg_alloc_err_err_end - msg_alloc_err_err
    rep stosb
.done
    ret

section .data

msg_alloc_err_no_avail	db 'Error: Not enough memory.  First avail block is', 0
msg_alloc_err_no_avail_end 
msg_alloc_err_com_full	db 'Error: Memory allocated to program full. ', 0
msg_alloc_err_com_full_end
msg_alloc_err_err	db 'Invalid error code.', 0
msg_alloc_err_err_end

    

section .bss

;----------
; Variables
;----------
first_avail_byte	resw 1	; First byte past end of .COM allocated memory
				; (i.e. past end of available memory)
