;******************************************************************************
; Initialized data for main part of DRVTEST3
;******************************************************************************

section .data

;--------------------------
; Pre-initialized variables
;--------------------------
cur_row			db 0
cur_col			db 0
cur_value		db 0

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
msg_sect_left_err	        db 'Error in sectors left: current sector ', 0
msg_divide_error		db 'Division error', 0
