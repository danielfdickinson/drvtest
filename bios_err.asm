;******************************************************************************
; BIOS Error Codes to String
;
; Exports: get_int13_err_code_string
;******************************************************************************

segment .data

bios_disk_err_success		db 'Success.', 0
bios_disk_err_invalid_function	db 'Invalid function in AH or invalid parameter.', 0
bios_disk_err_address_mark_not_found	db 'Address mark not found.', 0
bios_disk_err_disk_write_protected 	db 'Disk write protected (floppy).', 0
bios_disk_err_sector_not_found		db 'Sector not found.', 0
bios_disk_err_reset_failed		db 'Reset failed (hard disk).', 0
bios_disk_err_disk_changed		db 'Disk changed (floppy).', 0
bios_disk_err_drive_param_activity_failed db 'Drive parameter activity failed (hard disk.', 0
bios_disk_err_DMA_overrun		db 'DMA overrun.', 0
bios_disk_err_attempted_DMA_across_64k db 'Attempted DMA across 64K boundary.', 0
bios_disk_err_bad_sector_detected	db 'Bad sector detected (hard disk).', 0
bios_disk_err_bad_track_detected	db 'Bad track detected (hard disk).', 0
bios_disk_err_unsupported_track_or_invalid_media	db 'Unsupported track or invalid media.', 0
bios_disk_err_invalid_number_of_sectors_on_format	db 'Invalid number of sectors in format (hard disk).', 0
bios_disk_err_control_data_address_mark_detected	db 'Control data address mark detected (hard disk).', 0
bios_disk_err_DMA_arbitration_out_of_range		db 'DMA arbitration level out of range (hard disk).', 0
bios_disk_err_uncorrectable_CRC_ECC_on_read		db 'Uncorrectable CRC or ECC error on read.', 0
bios_disk_err_data_ECC_corrected	db 'Data ECC corrected (hard disk).', 0
bios_disk_err_controller_failure	db 'Controller failure.', 0
bios_disk_err_seek_failed		db 'Seek failed.', 0
bios_disk_err_timeout_not_ready		db 'Timeout (not ready).', 0
bios_disk_err_drive_not_ready		db 'Drive not ready (hard disk).', 0
bios_disk_err_undefined_error		db 'Undefined error (hard disk).', 0
bios_disk_err_write_fault		db 'Write fault (hard disk).', 0
bios_disk_err_status_register_error	db 'Status register error (hard disk).', 0
bios_disk_err_sense_operation_failed	db 'Sense operation failed (hard disk).', 0

segment .text

;-------------------------------
; Print BIOS Disk I/O Error Code
; IN: ah = error code
; OUT: AX = offset into data segment of error string
; If BIOS_ERR_FAR then DS = data segment of error string
;
get_int13_err_code_string:

%macro load_bios_disk_err 1
    jnz %%next
    mov ax, word bios_disk_err_%1
    jmp .done
%%next   
%endmacro

   cmp ah, 00h
   load_bios_disk_err success
   cmp ah, 01h
   load_bios_disk_err invalid_function
   cmp ah, 02h
   load_bios_disk_err address_mark_not_found
   cmp ah, 03h
   load_bios_disk_err disk_write_protected
   cmp ah, 04h
   load_bios_disk_err sector_not_found
   cmp ah, 05h
   load_bios_disk_err reset_failed
   cmp ah, 06h
   load_bios_disk_err disk_changed
   cmp ah, 07h
   load_bios_disk_err drive_param_activity_failed
   cmp ah, 08h
   load_bios_disk_err DMA_overrun
   cmp ah, 09h
   load_bios_disk_err attempted_DMA_across_64k
   cmp ah, 0ah
   load_bios_disk_err bad_sector_detected
   cmp ah, 0bh
   load_bios_disk_err bad_track_detected
   cmp ah, 0ch
   load_bios_disk_err unsupported_track_or_invalid_media
   cmp ah, 0dh
   load_bios_disk_err invalid_number_of_sectors_on_format
   cmp ah, 0eh
   load_bios_disk_err control_data_address_mark_detected
   cmp ah, 0fh
   load_bios_disk_err DMA_arbitration_out_of_range
   cmp ah, 10h
   load_bios_disk_err uncorrectable_CRC_ECC_on_read
   cmp ah, 11h
   load_bios_disk_err data_ECC_corrected
   cmp ah, 20h
   load_bios_disk_err controller_failure
   cmp ah, 40h
   load_bios_disk_err seek_failed
   cmp ah, 80h
   load_bios_disk_err timeout_not_ready
   cmp ah, 0aah
   load_bios_disk_err drive_not_ready
   cmp ah, 0bbh
   load_bios_disk_err undefined_error
   cmp ah, 0cch
   load_bios_disk_err write_fault
   cmp ah, 0e0h
   load_bios_disk_err status_register_error
   cmp ah, 0ffh
   load_bios_disk_err sense_operation_failed

.done
    %ifdef BIOS_ERR_FAR
    push ax
    mov ax, BIOS_DATA
    mov ds, ax
    pop ax
   retf
%else
   ret
%endif

