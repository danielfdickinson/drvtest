;******************************************************************************
; $Id: main.asm,v 1.1 2004/02/18 15:00:15 dfd Exp dfd $
;
; Main source file for DRVTEST.COM
;
; ChangeLog
; 
; $Log: main.asm,v $
; Revision 1.1  2004/02/18 15:00:15  dfd
; Initial revision
;
;
;******************************************************************************

BITS16						; DOS real mode

org 100h

;------------------------------------------------------------------------------
; Entry point to asm routines for DRVTEST.COM
;------------------------------------------------------------------------------
section .text

.param_init
   push bp

.data_seg_reg_init
   mov ax, cs			; Initial ES=DS=CS
   mov ds, ax
   mov es, ax
   call init_com_alloc		; Find and store how much memory we've been
				; allocated (for a .COM)

   call clear_screen		; Clear the screen

.out_seg_alloc
   mov di, out_seg
   mov bx, BUFFER_SIZE / 16
   call perform_alloc
   jnc .in_seg_alloc		; No error so continue
				; Else
   jmp .main_exit		; Exit

.in_seg_alloc
   mov di, in_seg
   mov bx, BUFFER_SIZE / 16
   call perform_alloc
   jc near .main_exit		; On error, exit

   call get_drive_param		; get drive parameters
   jc near .main_exit		; On error, exit

   call check_bytes_per_sector
   jc .main_exit		; On error,exit

   mov al, 0
   call fill_out_buf		; We want to write all zeroes (al)

   call init_out_dap		; Init out disk address packet

   mov [string_loc], word msg_done_init		; So far, so good

   call print_string
   mov [cur_col], byte 0
   inc byte [cur_row]

.value_loop:
   call init_write_loop

.write_loop:
   call calc_sector_start	; Figure out next start sector, and #sect to 
				; transfer
   call do_write		; write

   jc .main_exit		; If there was an error, exit

   mov bx, next_sector        	; If next sector == -1 we're done this write
   cmp [bx + 4], dword -1
   jnz .do_next_write		;     (!= -1 so do another write)
   cmp [bx], dword -1
   jz .next_value        ;   (== -1 so choose next value and start write loop)

.do_next_write
   mov cx, 8
.cur_next_copy_loop
   mov si, next_sector
   mov di, cur_sector
   rep movsb
   jmp .write_loop

.next_value:
   inc byte [cur_value]	; next value
   jz .main_exit	; keep going til we hit zero (roll over after 255)
   call fill_out_buf
   jmp .value_loop

.main_exit
   inc byte [cur_row]
   mov ah, 02		; Set cursor position
   mov bh, 00		; page 0
   mov dh, [cur_row]	; row
   mov dl, 0		; col
   int 10h
   pop bp
   retf

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

; Byte to fill buffer with in [cur_val]
fill_out_buf:
   ; Fill out output buffer with al
   push es
   mov al, [cur_value]
   mov di, 0
   mov bx, [out_seg]
   mov es, bx
   mov cx, BUFFER_SIZE
   rep stosb
   pop es
   ret

init_out_dap:
   ; Prepare invariant part of output disk address packet (dap)
   mov [dap.size], byte dap_v1_size
   mov [dap.sectors_to_transfer], word SECTORS_PER_TRANSFER
   mov [dap.transfer_buffer_low], word 0 ; Low word of transfer buffer address
   mov bx, [out_seg]
   mov [dap.transfer_buffer_high], bx	; High word of transfer buffer address
   ret

init_write_loop:
   mov ax, cs
   mov es, ax
   mov ds, ax
   cld
   mov cx, 8				; qword for abs sector is 8 bytes
   mov si, dpt.total_sectors
   mov di, cur_sector
   rep movsb
   mov [next_sector_high], dword 0

.num_sectors_less_1
;    Sector numbers start at zero so take num_sectors - 1
    mov bx, cur_sector
    mov eax, [bx]
    sub eax, 1
    mov [bx], eax
    mov eax, [bx + 4]
    sbb eax, 0
    mov [bx + 4], eax

.set_num_sectors_to_transfer
   mov ax, SECTORS_PER_TRANSFER
   mov bx, dap.sectors_to_transfer
   mov [bx], ax
.set_cur_value
   mov [cur_value], byte 0

.done
   ret

;-------------------
; Write sector group
;
do_write:
   mov bx, cur_sector			; Start at the cur_sector'th sector

   cmp [dap.sectors_to_transfer], byte 1 ; Skip divide if we're doing 1 sector
					; at a time
   jz .copy_abs_sect_num
   mov edx, [bx + 4]			; Divide by num sectors to transfer
   mov eax, [bx]			;   because func 43h moves _blocks_   
   xor ecx, ecx
   xor ebx, ebx
   mov bx, [dap.sectors_to_transfer]	
   call qword_divide
   jnc .continue
   mov [string_loc], word msg_divide_error
   call print_string
   ret

.continue:
   mov [dap.abs_sect_start_high], ecx
   mov [dap.abs_sect_start_low], ebx
   jmp .do_it

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

.write_msg:
   mov [cur_col], byte 0
   call clear_eol
   mov [string_loc], word msg_write_sector_start
   call print_string
   mov edx, [cur_sector + 4]
   mov eax, [cur_sector]
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
   mov edx, [cur_sector + 4]
   mov eax, [cur_sector]
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
   stc
.done
   ret

calc_sector_start:


; ******** DEBUG CODE *****************
   mov ebx, SECTORS_PER_TRANSFER
   mov eax, [cur_sector]
   sub eax, ebx ; Try just subtracting the #sectors written
   mov [next_sector], eax
   ret
; *************************************

   ; Calculate next sector start address
   ; Carry set if #sector's left less than SECTORS_PER_TRANSFER - 1
   mov bx, cur_sector
;   mov eax, [bx + 4]
   mov ecx, SECTORS_PER_TRANSFER - 1
   sub eax, ecx
   mov bx, next_sector
   mov [bx + 4], eax
   mov bx, cur_sector
   mov eax, [bx]
   sbb eax, 0
   mov bx, next_sector
   mov [bx], eax
   jnc near .done	; No borrow so we're still doing a full buffer r/w

   ; Calculate num_sectors - cur_sector (this is # of sectors left to transfer)
   cmp eax, ecx
   jnz .sect_left_err	; Since sectors per transfer is a word, the high double
   		; word should never differ from cur_sector and num_sectors

   ; Set next sector to -1 (so we know we're done)
   mov bx, next_sector
   mov eax, -1
   mov [bx], eax
   mov [bx + 4], eax

   mov di, 0
   mov bx, dpt.total_sectors_low
   mov eax, [bx]
   mov bx, cur_sector
   mov ecx, [bx]
   sub eax, ecx
   jnz .compare_high
   mov di, 1
.compare_high
   mov edx, eax
   mov bx, dpt.total_sectors_high
   mov eax, [bx]
   mov bx, cur_sector + 4
   mov ecx, [bx]
   sub eax, ecx
   jb .sect_left_err   	; current sector should never exceed or equal max
   jne .calc_remainder
   cmp di, 1
   je .sect_left_err
.calc_remainder
   mov eax, edx
   mov bx, [dap + 2]
   mov [bx], dx
   jmp .done

.sect_left_err
   mov [cur_col], byte 0
   inc byte [cur_row]
   mov [string_loc], word msg_sect_left_err
   call print_string
   mov edx, [cur_sector + 4]
   mov eax, [cur_sector]
   mov ebx, 10
   call print_number
   stc
.done
   ret


;*********************************************************
; Store data in a separate files to keep things manageable
;---------------------------------------------------------
%include "screen.asm"
%include "main_data.asm"
%include "main_bss.asm"
%include "bios_err.asm"
%include "const.asm"
%include "dos_err.asm"
%include "com_mem.asm"
%include "qwords.asm"
