;******************************************************************************
; $Id$
;
; Initialize a .COM program
;
; ChangeLog
; 
; $Log$
;
;******************************************************************************

%ifndef __INIT_COM
%define __INIT_COM

;--------------------------------------
; Initialize registers (including stack)
;
; The symbol end_of_bss must be the offset of the first byte beyond all memory
; used by .COM
;
%macro m_initialize_registers 1		; 1 dummy parameter

	mov ax, cs
        mov es, ax			; DS=ES=CS
        mov ds, ax

%endmacro ; end initialize_registers

%macro m_initialize_stack 1		; 1 parameter: stack size
	mov ax, cs			; Starts as CS=DS=ES=SS for .COM
	mov bx, (end_of_bss + %1) 	; end_of_.com + stack_size = offset
	shr bx, 4			;    shifted right 4 bits = segment
        add bx, ax			; cs + segment portion of stack + 1 =
	inc bx				;    new stack segment

	mov bp, sp			; bp = sp
	mov si, bp			;    Source = old stack (ds=ss=cs):sp
        mov ax, bx
        mov es, ax			;    Destination = new stack
        mov di, bp			;        (es=new ss):sp

.copy_stack:
	lodsb				; ds:si = old stack byte
        stosb				;   new stack byte (es:di) = 
					;      old stack byte
        cmp di, 00h			; when si=di=0, we're done
        jnz .copy_stack			;     This works because of rollover

.use_new_stack:
        mov ss, ax			; The new stack is ready, so use it
        mov sp, bp			;    Not really necessary but just in
					;       case, set the stack point (sp) 

%endmacro ; m_initialize_stack stack_size

;------------------------------------------------------------------------
; Initialize memory tracking for base (below 1MB) memory allocated by DOS
;
; 
%macro m_initialize_base_mem_tracking 1	; 1 dummy parameter

   mov ax, [02h]		; Offset 02h in PSP is seg of first byte past
				;    memory allocated to .COM
   mov [first_unalloc_byte], ax	; Store that info

%endmacro ; end m_initialize_base_mem_tracking

section .text

;----------------------------------
; Generic initialization for a .COM
;
init_com:			; Perform all calls used to initialize
				;    a generic .COM 

	m_initialize_stack STACK_SIZE	; Initialize stack (.COM)
	m_initialize_registers 1	; Initialize registers
   	m_initialize_base_mem_tracking 1; Initialize tracking of allocated
					;   base (<1MB) memory
	ret


;-----------------------------------------------
; Uninitialized data for initialization routines
;

;section .bss

;----------
; Variables
;----------

%endif ; __INIT_COM
