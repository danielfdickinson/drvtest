;******************************************************************************
; Initialized data for main part of DRVTEST3
;******************************************************************************

section .data

;----------------------
; Initialized Variables
;
cur_value			db 0	; Current byte being written to disk

cur_sector:				; Current sector 
cur_sector_low			dd 0	
cur_sector_high			dd 0

next_sector:				; Next sector 
next_sector_low			dd 1
next_sector_high		dd 1

;------------------
; String constants
;------------------
msg_param_get_err_start		db 'Error getting disk parameters: ',0
msg_param_display_start		db 'Drive has ', 0
msg_param_display_continue	db ' sectors with ', 0
msg_param_display_continue2 	db ' bytes per sector.', 0
msg_param_display_chs		db 'C H S = ', 0
msg_done_init			db 'Done initialization.', 0
msg_byte_count_err     db 'Bytes per sector invalid. We need 512, drive has ',0
msg_write_sector_start		db 'Writing sector ', 0
msg_write_sector_continue	db ', value = ', 0
msg_write_error_start		db 'Error writing sector ', 0
msg_write_error_value		db ', value = ', 0
msg_read_sector_start		db 'Reading sector ', 0
msg_read_sector_continue	db ', value = ', 0
msg_read_error_start		db 'Error reading sector ', 0
msg_read_error_value		db ', value = ', 0
msg_sect_left_err	        db 'Error in sectors left: current sector ', 0
msg_divide_error		db 'Division error', 0
msg_dap_error			db 'DAP for error: ', 0
;msg_int13x_not_supported	db 'INT 13 Extensions not supported.', 0
;msg_int13x_rw_not_supported	db 'INT 13 Extended read/write not supported.', 0
;msg_edpt_not_supported		db 'INT 13 Extended Disk Parameter Table not supported.', 0
