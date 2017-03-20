;******************************************************************************
; $Id: main.asm,v 1.2 2004/02/18 15:25:24 dfd Exp dfd $
;
; Main source file for DRVTEST.COM
;
; ChangeLog
; 
; $Log: main.asm,v $
; Revision 1.2  2004/02/18 15:25:24  dfd
; *** empty log message ***
;
;
;******************************************************************************

BITS16						; DOS real mode

org 100h

;------------------------------------------------------------------------------
; Entry point to asm routines for DRVTEST.COM
;------------------------------------------------------------------------------

section .text

main:
   call init_com		; Generic initialization of registers
				;    stack, and memory tracking
   call init_display		; Initialize display (clear screen, set cursor)

   call init_drvtest		; DRVTEST.COM-specific initialization

.io_seg_alloc
   mov di, io_seg
   mov bx, BUFFER_SIZE / 16
   call perform_alloc
   jnc .cont_init		; No error so continue
				; Else
   jmp .main_exit		; Exit

.cont_init:
   call get_drive_param		; get drive parameters
   jc near .main_exit		; On error, exit

   call check_bytes_per_sector
   jc near .main_exit		; On error,exit

   mov al, 0
   call fill_out_buf		; We want to write all zeroes (al)

   call init_out_dap		; Init out disk address packet

   mov [string_loc], word msg_done_init		; So far, so good

   call print_string
   mov [cur_col], byte 0
   inc byte [cur_row]
   mov [cur_value], byte 0

.value_loop:
   call fill_out_buf		; We want to write all zeroes (al)
   call init_out_dap		; Init out disk address packet
   call init_write_loop
   mov ax, cs
   mov ds, ax
   mov es, ax

.write_loop:
   call calc_sector_start	; Figure out next start sector, and #sect to 
				; transfer
   mov eax, [next_sector_low]   ; If next sector >= last sector, we're done
   mov edx, [next_sector_high]
   sub eax, [dpt.total_sectors_low]
   sbb edx, [dpt.total_sectors_high]
   jc .do_write			; Otherwise we keep going
   jmp .init_read_loop		; next sector > last sector so read back values

.do_write
   call do_write		; write
   jc .main_exit		; If there was an error, exit

   mov ax, cs
   mov ds, ax
   mov es, ax
   mov cx, 8			; Otherwise cur_sector = next_sector
.cur_next_copy_loop		;    and loop (to .write_loop)
   mov si, next_sector
   mov di, cur_sector
   rep movsb
   jmp .write_loop

.init_read_loop
   call init_out_dap		; Init out disk address packet
   call init_read_loop
   mov ax, cs
   mov ds, ax
   mov es, ax

.read_loop
   call calc_sector_start	; Figure out next start sector, and #sect to 
				; transfer
   mov eax, [next_sector_low]   ; If next sector >= last sector, we're done
   mov edx, [next_sector_high]
   sub eax, [dpt.total_sectors_low]
   sbb edx, [dpt.total_sectors_high]
   jc .do_read			; Otherwise we keep going
   jmp .next_value		; next sector > last sector so try next value

.do_read
   call do_read			; read

   jc .main_exit		; If there was an error, exit

   mov ax, cs
   mov ds, ax
   mov es, ax
   mov cx, 8			; Otherwise cur_sector = next_sector
.cur_next_copy_read_loop:		;    and loop (to .write_loop)
   mov si, next_sector
   mov di, cur_sector
   rep movsb
   jmp .read_loop

.next_value:
   inc byte [cur_value]	; next value
   jz .main_exit	; keep going til we hit zero (roll over after 255)
   call fill_out_buf
   jmp .value_loop

.main_exit

;------------------------------------
; DRVTEST.COM-specific initialization
;
init_drvtest:
	call allocate_io_buffer		; 


;-----------------------------------------------
; Allocate a <= 64k buffer for sector read/write
;
allocate_io_buffer:
	mov di, io_seg			; Location to store io_seg
 	mov bx, BUFFER_SIZE / 16 + 1	;    Size of buffer in paragraphs
	call perform_alloc
	jc .error			; CF set = error
	ret				; No error so return

.error
	pop ax				; We're going to exit so get rid
					; of return address
        mov ax, 1			;    Return code = 1
	jmp exit			; Exit(1)

;--------
; Exit(x)
;
; IN: al = return code
; OUT: program terminated
;
exit:
   call set_cursor_position

   mov ah, 04Ch
   mov al, 00
   int 21h

;--------------------------
; Perform memory allocation
; 
; Print message and exit on error
; Clear carry on success
;
; IN: BX = requested size in paragraphs
;     string_loc is where to store pointer to error string
;     print_buffer is where to store error string
;     ES:DI = where to store address of allocated seg
perform_alloc
   call allocate_segment
   jnc 	.alloc_ok
   mov ax, cs
   mov es, ax
   mov 	di, print_buffer   
   call get_com_mem_error_string
   mov 	[string_loc], word print_buffer
   call print_string
   stc
   jmp .exit
.alloc_ok
   stosw
   clc
.exit
   ret

;-----------------------------------
; Get Drive Parameters (using INT13X)
;
get_drive_param:
   ; Get Drive Parameters
   mov ah, 0x48
   mov dl, 0x80
   mov si, dpt
   mov [si], word dpt_v1_size
   int 13h
   jnc .display_param
.print_err
   mov [string_loc], word msg_param_get_err_start
   call print_string
   call get_int13_err_code_string
   mov [string_loc], ax
   call print_string
   mov [cur_col], byte 0
   inc byte [cur_row]
   jmp .exit_err
.display_param
   mov [string_loc], word msg_param_display_chs
   call print_string
   xor edx, edx
   mov eax, [dpt.cylinders]
   mov ebx, 10
   call print_number
   inc byte [cur_col]
   xor edx, edx
   mov eax, [dpt.heads]
   mov ebx, 10
   call print_number
   inc byte [cur_col]
   xor edx, edx
   mov eax, [dpt.sectors]
   mov ebx, 10
   call print_number
   mov [cur_col], byte 0
   inc byte [cur_row]

   mov [string_loc], word msg_param_display_start
   call print_string
   mov edx, [dpt.total_sectors_high]
   mov eax, [dpt.total_sectors_low]
   mov ebx, 10
   call print_number
   mov [string_loc], word msg_param_display_continue
   call print_string
   xor edx, edx
   xor eax, eax
   mov ax, [dpt.byte_count]
   mov ebx, 10
   call print_number
   mov [string_loc], word msg_param_display_continue2
   call print_string
   mov [cur_col], byte 0
   inc byte [cur_row]
   clc
   jmp .exit_ok
.exit_err
   stc
.exit_ok
   ret

;-------------------------------
; Verify Bytes Per Sector == 512
;
check_bytes_per_sector
   cmp [dpt.byte_count], word BYTES_PER_SECTOR
   jz .bytes_ok
   mov [string_loc], word msg_byte_count_err
   call print_string
   xor eax, eax
   mov ax, [dpt.byte_count]
   xor edx, edx
   mov ebx, 10
   call print_number
   mov [cur_col], byte 0
   inc byte [cur_row]
   stc
.bytes_ok
   ret

;--------------------------------
; Fill output buffer with a value
; Byte to fill buffer with in [cur_val]
;
fill_out_buf:
   ; Fill out output buffer with al
   push es
   mov al, [cur_value]
   mov di, 0
   mov bx, [io_seg]
   mov es, bx
   mov cx, BUFFER_SIZE
   rep stosb
   pop es
   ret

;------------------------------------------
; Initialize Disk Address Packet for output
;
init_out_dap:
   ; Prepare invariant part of output disk address packet (dap)
   mov [dap.size], byte dap_v1_size
   mov [dap.sectors_to_transfer], word SECTORS_PER_TRANSFER
   mov [dap.transfer_buffer_low], word 0 ; Low word of transfer buffer address
   mov bx, [io_seg]
   mov [dap.transfer_buffer_high], bx	; High word of transfer buffer address
   ret

;-----------------------------------------------------------------
; Initialize loop that writes a given value to every sector on disk
;
init_write_loop:
   xor edx, edx				; Cur sector = 0
   mov [cur_sector_low], edx
   mov [cur_sector_high], edx

.set_num_sectors_to_transfer
   mov ax, SECTORS_PER_TRANSFER		; set size of blocks (in sectors)
   mov [dap.sectors_to_transfer], ax		
   mov [cur_sect_to_transfer], ax

   mov [next_sector_low], dword 1	; Next sector = 1
   mov [next_sector_high], dword 0

.done
   ret

;-----------------------------------------------------------------
; Initialize loop that reads a given value to every sector on disk
;
init_read_loop:
   xor edx, edx				; Cur sector = 0
   mov [cur_sector_low], edx
   mov [cur_sector_high], edx

.set_num_sectors_to_transfer
   mov ax, SECTORS_PER_TRANSFER		; set size of blocks (in sectors)
   mov [dap.sectors_to_transfer], ax		
   mov [cur_sect_to_transfer], ax

   mov [next_sector_low], dword 1	; Next sector = 1
   mov [next_sector_high], dword 0

.done
   ret

;-------------------
; Write sector group
;
do_write:

.copy_abs_sect_num:
   mov eax, [cur_sector_high]
   mov [dap.abs_sect_start_high], eax
   mov eax, [cur_sector_low]
   mov [dap.abs_sect_start_low], eax

.do_it:
   mov ax, cs
   mov ds, ax
   mov si, dap				; Address of disk address packet (dap)
   mov ah, 43h				; Extended Write
   mov al, 02h				; Verify writes
   xor dx, dx
   mov dl, 80h	 			; Drive number
   int 13h				; BIOS Disk I/O
   jc .error

   call debug_display
   clc

.write_msg:
   mov [cur_col], byte 0
   call clear_eol
   mov [string_loc], word msg_write_sector_start
   call print_string
   mov edx, [cur_sector_high]
   mov eax, [cur_sector_low]
   mov ebx, 10
   call print_number
   mov [string_loc], word msg_write_sector_continue
   call print_string
   xor edx, edx
   xor eax, eax
   mov al, [cur_value]
   mov ebx, 10
   call print_number
   call clear_eol
   clc
   jmp .done

.error
   push ax
   inc byte [cur_row]
   mov [cur_col], byte 0
   mov [string_loc], word msg_write_error_start
   call print_string
   mov edx, [cur_sector_high]
   mov eax, [cur_sector_low]
   mov ebx, 10
   call print_number
   mov [string_loc], word msg_write_error_value
   call print_string
   xor edx, edx
   xor eax, eax
   mov al, [cur_value]
   mov ebx, 10
   call print_number
   mov [cur_col], byte 0
   inc byte [cur_row]
   pop ax
   call get_int13_err_code_string
   mov [string_loc], ax
   call print_string
   mov [cur_col], byte 0
   inc byte [cur_row]
   mov [string_loc], word msg_dap_error
   call print_string
   xor edx, edx
   xor eax, eax
   mov al, [dap.size]
   mov ebx, 16
   call print_number
   inc byte [cur_col]
   xor edx, edx
   xor eax, eax
   mov ax, [dap.sectors_to_transfer]
   mov ebx, 10
   call print_number
   inc byte [cur_col]
   xor edx, edx
   xor eax, eax
   mov ax, [dap.transfer_buffer_low]
   mov ebx, 16
   call print_number
   inc byte [cur_col]
   xor edx, edx
   xor eax, eax
   mov ax, [dap.transfer_buffer_high]
   mov ebx, 16
   call print_number
   inc byte [cur_col]
   xor edx, edx
   mov eax, [dap.abs_sect_start_low]
   mov ebx, 16
   call print_number
   inc byte [cur_col]
   xor edx, edx
   mov eax, [dap.abs_sect_start_high]
   mov ebx, 16
   call print_number
   inc byte [cur_col]
   mov eax, [dap.abs_sect_start_low]
   mov edx, [dap.abs_sect_start_high]
   mov ebx, 10
   call print_number
   stc
.done
   ret

;-------------------
; Read sector group
;
do_read:

.copy_abs_sect_num:
   mov eax, [cur_sector_high]
   mov [dap.abs_sect_start_high], eax
   mov eax, [cur_sector_low]
   mov [dap.abs_sect_start_low], eax

   ; Write buffer with inverse of current value
   mov ax, io_seg
   mov es, ax
   mov di, 0
   mov cx, BUFFER_SIZE
   mov al, [cur_value]
   neg al
   rep stosb

.do_it:
   mov ax, cs
   mov ds, ax
   mov si, dap				; Address of disk address packet (dap)
   mov ah, 42h				; Extended Read
   xor dx, dx
   mov dl, 80h	 			; Drive number
   int 13h				; BIOS Disk I/O
   jc .read_error

   call debug_display
   clc

.verify_value
   ; Write buffer with inverse of current value
   mov ax, io_seg
   mov es, ax
   mov di, 0
   mov cx, BUFFER_SIZE
   mov al, [cur_value]
.verify_loop
   cmp al, [es:di]
   jnz .read_error
   inc di
   loop .verify_loop      

.read_msg:
   mov [cur_col], byte 0
   call clear_eol
   mov [string_loc], word msg_read_sector_start
   call print_string
   mov edx, [cur_sector_high]
   mov eax, [cur_sector_low]
   mov ebx, 10
   call print_number
   mov [string_loc], word msg_read_sector_continue
   call print_string
   xor edx, edx
   xor eax, eax
   mov al, [cur_value]
   mov ebx, 10
   call print_number
   call clear_eol
   clc
   jmp .done

.read_error
   push ax
   xor eax, eax
   mov ax, di
   mov bx, 512 ; (bytes per sector)
   div bx
   and dx, dx		; Are we in middle of a sector?
   jz .add_sector       ; No, just add sector in buffer to absolute sector
   xor edx, edx
   add ax, 1   
.add_sector  
   add eax, [cur_sector_low]
   adc edx, [cur_sector_high]

   push eax
   push edx
   inc byte [cur_row]
   mov [cur_col], byte 0
   mov [string_loc], word msg_write_error_start
   call print_string
   pop eax
   pop edx
   mov ebx, 10
   call print_number
   mov [string_loc], word msg_write_error_value
   call print_string
   xor edx, edx
   xor eax, eax
   mov al, [cur_value]
   mov ebx, 10
   call print_number
   mov [cur_col], byte 0
   inc byte [cur_row]
   pop ax
   call get_int13_err_code_string
   mov [string_loc], ax
   call print_string
   mov [cur_col], byte 0
   inc byte [cur_row]
   stc
.done
   ret


calc_sector_start:

.next_start_address
   ; Calculate next sector start address
   mov eax, [cur_sector_low]
   mov edx, [cur_sector_high]
   xor ecx, ecx
   mov cx, [cur_sect_to_transfer]
   add eax, ecx
   adc edx, dword 0
   mov [next_sector_low], eax
   mov [next_sector_high], edx

   sub eax, [dpt.total_sectors_low]	; If next_sector >= total_sectors
   sbb edx, [dpt.total_sectors_high]
   jae .start_single_sector_writes	; Switch to single sector writes
;   jnz .done
;   inc byte [cur_row]
;   mov [string_loc], msg_here
;   call print_string
.done
   ret

.start_single_sector_writes
   xor ecx, ecx
   mov cx, [cur_sect_to_transfer]
   cmp cx, word 01h
   je .done
   sub [cur_sector_low], ecx            ; Otherwise undo sector add
   sbb [cur_sector_high], dword 0
   sub [next_sector_low], ecx
   sbb [next_sector_high], dword 0
   mov ecx, 01h				; And add only a single sector
   mov [cur_sect_to_transfer], cx
   mov [dap.sectors_to_transfer], cx	; and update DAP
   jmp .next_start_address

;   mov eax, [cur_sector_low]
;   mov edx, [cur_sector_high]
;   add eax, ecx
;   adc edx, dword 0
;   mov [next_sector_low], eax
;   mov [next_sector_high], edx
;   jmp .done

;--------------------------
; Determine INT 13h capabilities
;
;int13ver:
;   mov ah, 41h
;   mov bx, 55AAh
;   mov dl, 80h
;   jc .int13x_err
;   test cx, 01h			; Extended r/w supported
;   jz .int13_rw_not_supported
;   test cx, 04h			; Extended Disk Parameter Table Supported
;   jnz .edpt_not_supported


;.edpt_not_supported
;   mov [string_loc], msg_edpt_not_supported
;   stc
;   ret

;.int13_rw_not_supported:
;   mov [string_loc], msg_int13x_rw_not_supported
;   stc
;   ret

;.int13x_err
;   mov [string_loc], msg_int13x_not_supported
;   stc
;   ret

;******************************************************************************
; Data for debug display
;

section .data
msg_current_value db 'Current value: ',0
msg_cur_num_sect db 'Current number of sectors to transfer: ', 0
msg_cur_cur_sector db 'Current sector: ', 0
msg_cur_next_sector db 'Next sector: ', 0
msg_dap_abs_sector db 'DAP absolute sector: ', 0

section .text

;
; Display contents of next sector, current sector, current value,
; and disk address packet
;
debug_display:
   push ebx
   push ecx
   push eax
   push edx
   push edi
   push esi
   push es
   push ds

   mov al, [cur_col]
   mov [save_cur_col], al
   mov al, [cur_row]
   mov [save_cur_row], al
   mov ax, [string_loc]
   mov [save_string_loc], ax
   mov [cur_col], byte 0
   mov [cur_row], byte 12
   mov [string_loc], word msg_current_value
   call print_string
   xor eax, eax
   xor edx, edx
   mov ebx, 16
   mov al, [cur_value]
   call print_number
   mov cx, 3
   call print_spaces
   xor eax, eax
   xor edx, edx
   mov ebx, 10
   mov al, [cur_value]
   call print_number
   mov cx, 10
   call print_spaces

   mov [cur_col], byte 0
   inc byte [cur_row]
   mov [string_loc], word msg_cur_num_sect
   call print_string
   xor eax, eax
   xor edx, edx
   mov ebx, 16
   mov ax, [cur_sect_to_transfer]
   call print_number
   mov cx, 3
   call print_spaces
   xor eax, eax
   xor edx, edx
   mov ebx, 10
   mov ax, [cur_sect_to_transfer]
   call print_number
   mov cx, 10
   call print_spaces

   mov [cur_col], byte 0
   inc byte [cur_row]
   mov [string_loc], word msg_cur_cur_sector
   call print_string
   mov ebx, 16
   mov eax, [cur_sector_low]
   mov edx, [cur_sector_high]
   call print_number
   mov cx, 3
   call print_spaces
   mov ebx, 10
   mov eax, [cur_sector_low]
   mov edx, [cur_sector_high]
   call print_number
   
   mov [cur_col], byte 0
   inc byte [cur_row]
   mov [string_loc], word msg_cur_next_sector
   call print_string
   mov ebx, 16
   mov eax, [next_sector_low]
   mov edx, [next_sector_high]
   call print_number
   mov cx, 3
   call print_spaces
   mov ebx, 10
   mov eax, [next_sector_low]
   mov edx, [next_sector_high]
   call print_number

   mov [cur_col], byte 0
   inc byte [cur_row]
   mov [string_loc], word msg_dap_abs_sector
   call print_string
   mov ebx, 16
   mov eax, [dap.abs_sect_start_low]
   mov edx, [dap.abs_sect_start_high]
   call print_number
   mov cx, 3
   call print_spaces
   mov ebx, 10
   mov eax, [dap.abs_sect_start_low]
   mov edx, [dap.abs_sect_start_high]
   call print_number
   mov cx, 10
   call print_spaces

   mov al, [save_cur_col]
   mov [cur_col], al
   mov al, [save_cur_row]
   mov [cur_row], al
   mov ax, [save_string_loc]
   mov [string_loc], ax

   pop ds
   pop es
   pop esi
   pop edi
   pop edx
   pop eax
   pop ecx
   pop ebx
   ret

 
;*********************************************************
; Store data in a separate files to keep things manageable
;---------------------------------------------------------
%include "misc.mac"
%include "init_com.asm"
%include "screen.asm"
%include "main_data.asm"
%include "main_bss.asm"
%include "bios_err.asm"
%include "const.asm"
%include "dos_err.asm"
%include "com_mem.asm"
%include "qwords.asm"

section .bss

save_cur_row resb 1
save_cur_col resb 1
save_string_loc resw 1

end_of_bss:

