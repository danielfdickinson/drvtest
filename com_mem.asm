;******************************************************************************
; $Id$
;
; Memory management for a .COM (for memory below 1MB)
;
; Assumes first_unalloc_byte has been initialize with first byte beyond that
; allocated to .COM (in DOS a .COM is allocated all available memory below
; 640k)
;
; Supplies the following macros:
;    m_get_def_data_seg /register/	; Load 16-bit register /register/
;					;   with data segment
; 
; ChangeLog
; 
; $Log$
;
;******************************************************************************

;-----------------------------------------------
; Load 16-bit register with default data segment
;
%macro m_get_def_data_seg 1	; 1 parameter (register to load with default
				;    data segment)

	m_find_reg_type %1
        %ifidn m_reg_type, general
		%if m_reg_size == 16
			mov %1, cs	; Default data segment = CS
		%else
			%error "Can't load segment into 8 or 32 bit registers"
		%endif
	%elifidn m_reg_type, segment
		push ax
		mov ax, cs		; Default data segment = CS
		mov %1, ax		
		pop ax
	%else
		%error "m_reg_type not segment or general in m_get_def_data_seg"
	%endif
%endmacro ; m_get_def_data_seg 1

;------------------------------
; Record memory usage in a .COM
;
; IN: 
;    BX = requested size in paragraphs
;    DS:SI = segment of address of end of code+data+bss
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
   mov ax, [first_unalloc_byte]	; Seg of first byte not available
   mov dx, end_of_bss		; Last byte of program
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
   mov [first_unalloc_byte], ax
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

;---------
; Messages
;---------
section .data

msg_alloc_err_no_avail	db 'Error: Not enough memory.  First avail block is', 0
msg_alloc_err_no_avail_end 
msg_alloc_err_com_full	db 'Error: Memory allocated to program full. ', 0
msg_alloc_err_com_full_end
msg_alloc_err_err	db 'Invalid error code.', 0
msg_alloc_err_err_end


;--------------------------------------------------------
; Uninitialized variables for memory management below 1MB
;

section .bss

;----------
; Variables
;----------
first_unalloc_byte	resw 1	; First byte past end of .COM allocated memory
