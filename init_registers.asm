;******************************************************************************
; $Id$
;
; Initialize registers (including stack) (16-bit DOS)
;
; ChangeLog
; 
; $Log$
;
;******************************************************************************

;--------------------------------------
; Initialize registers (including stack)
;
; The symbol end_of_bss must be the offset of the first byte beyond all memory
; used by .COM
;
%macro initialize_registers 1		; 1 parameter (stack size)

	mov ax, cs			; Starts as CS=DS=ES=SS for .COM
	mov bx, (end_of_bss + %1) >> 4	; end_of_.com + stack_size = offset
					;    shifted right 4 bits = segment
        add bx, ax			; cs + segment portion of stack = 
					;    new stack segment

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

	mov ax, cs
        mov es, cs			; DS=ES=CS
        mov ds, cs
%endmacro
