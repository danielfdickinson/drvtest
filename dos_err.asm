;******************************************************************************
; Translate DOS Error Code into a string
;
;******************************************************************************

segment .data

dos_err_ok			db 'Operation completed successfully.', 0
dos_err_invalid_function	db 'Invalid function number.', 0
dos_err_file_not_found		db 'File not found.', 0
dos_err_path_not_found		db 'Path not found.', 0
dos_err_too_many_open_files	db 'Too many open files.', 0
dos_err_access_denied      	db 'Access denied.', 0
dos_err_invalid_handle		db 'Invalid handle.', 0
dos_err_mcb_destroyed		db 'Memory control block destroyed.', 0
dos_err_insufficient_memory	db 'Insufficient memory.', 0
dos_err_memory_block_address_invalid db 'Memory block address invalid.',0
dos_err_environment_invalid	db 'Environment Invalid.', 0
dos_err_format_invalid		db 'Format invalid.', 0
dos_err_access_code_invalid	db 'Access code invalid.',0
dos_err_data_invalid		db 'Data invalid.',0
dos_err_reserved_01		db 'Unknown error (reserved).',0
dos_err_invalid_drive		db 'Invalid drive.',0
dos_err_attempted_to_remove_cwd db' Attempted to remove current directory.'
dos_err_not_same_device		db 'Not same device.', 0
dos_err_no_more_files		db 'No more files.', 0
dos_err_disk_write_protected	db 'Disk write protected.', 0
dos_err_unknown_unit		db 'Unknown unit.', 0
dos_err_drive_not_ready		db 'Drive not ready.', 0
dos_err_unknown_command		db 'Unknown command.', 0
dos_err_data_error_crc		db 'Data error (CRC bad).', 0
dos_err_bad_request_structure_length db 'Bad request structure length.', 0
dos_err_seek_error		db 'Seek error.', 0
dos_err_unknown_media_type 	db 'Unknown media type.', 0
dos_err_sector_not_found	db 'Sector not found.', 0
dos_err_printer_out_of_paper  db 'Printer out of paper.', 0
dos_err_write_fault		db 'Write fault.', 0
dos_err_read_fault		db 'Read fault.', 0
dos_err_general_failure		db 'General failure.', 0
dos_err_sharing_violation	db 'Sharing violation.', 0
dos_err_lock_violation		db 'Lock violation.', 0
dos_err_disk_change_invalid	db 'Disk change invalid.', 0
dos_err_fcb_unavailable		db 'FCB unavailable.', 0
dos_err_sharing_buffer_overflow db 'Sharing buffer overflow.', 0
dos_err_code_page_mismatch	db 'Code page mismatch.', 0
dos_err_out_of_input		db 'Out of input.', 0
dos_err_insufficient_disk_space db 'Insufficient disk space.', 0
;dos_err_reserved_02		db 'Unknown error (reserved).',0
;dos_err_reserved_03		db 'Unknown error (reserved).',0
;dos_err_reserved_04		db 'Unknown error (reserved).',0
;dos_err_reserved_05		db 'Unknown error (reserved).',0
;dos_err_reserved_06		db 'Unknown error (reserved).',0
;dos_err_reserved_07		db 'Unknown error (reserved).',0
;dos_err_reserved_08		db 'Unknown error (reserved).',0
;dos_err_reserved_09		db 'Unknown error (reserved).',0
;dos_err_reserved_10		db 'Unknown error (reserved).',0
;dos_err_reserved_11		db 'Unknown error (reserved).',0

dos_err_table:
dw dos_err_ok, dos_err_invalid_function, dos_err_file_not_found
dw dos_err_path_not_found, dos_err_too_many_open_files, dos_err_access_denied
dw dos_err_invalid_handle, dos_err_mcb_destroyed, dos_err_insufficient_memory
dw dos_err_memory_block_address_invalid, dos_err_environment_invalid
dw dos_err_format_invalid, dos_err_access_code_invalid, dos_err_data_invalid,
dw dos_err_reserved_01, dos_err_invalid_drive, dos_err_attempted_to_remove_cwd
dw dos_err_not_same_device, dos_err_no_more_files, dos_err_disk_write_protected
dw dos_err_unknown_unit, dos_err_drive_not_ready, dos_err_unknown_command
dw dos_err_data_error_crc, dos_err_bad_request_structure_length
dw dos_err_seek_error, dos_err_unknown_media_type, dos_err_sector_not_found
dw dos_err_printer_out_of_paper, dos_err_write_fault, dos_err_read_fault
dw dos_err_general_failure, dos_err_sharing_violation, dos_err_lock_violation
dw dos_err_disk_change_invalid, dos_err_fcb_unavailable
dw dos_err_sharing_buffer_overflow, dos_err_code_page_mismatch
dw dos_err_out_of_input, dos_err_insufficient_disk_space
; dw  dos_err_reserved_02, dos_err_reserved_03, dos_err_reserved_04
; dw  dos_err_reserved_05, dos_err_reserved_06, dos_err_reserved_07
; dw  dos_err_reserved_08, dos_err_reserved_09, dos_err_reserved_10
; dw  dos_err_reserved_11
; All further errors are network related

segment .text

;-----------------------------------
; Translate DOS Error Code To String
; IN: AX = err_code
; OUT: AX = offset into data segment of error code string

get_dos_err_code_string:
      push bx
      mov bx, dos_err_table
      shl ax, 1
      add bx, ax
      mov ax, [bx]
      pop bx
      ret
