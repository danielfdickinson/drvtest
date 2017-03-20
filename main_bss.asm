;******************************************************************************
; Uninitialized data for main part of DRVTEST3
;******************************************************************************

section .bss

;----------
; Variables
;----------
io_seg    			resw 1	; Address of block for i/o buffer
cur_sect_to_transfer		resw 1 	; Current # sectors per write

;-------------------
; One-off structures
;-------------------

;
; Disk Address Packet
;

dap:
   .size			resb 1
   .reserved		        resb 1
   .sectors_to_transfer		resw 1
   .transfer_buffer
   .transfer_buffer_low	   	resw 1
   .transfer_buffer_high   	resw 1
   .abs_sect_start:
   .abs_sect_start_low  	resd 1
   .abs_sect_start_high 	resd 1
dap_v1_end:
   .buffer_64_flat		resd 2
dap_v2_end:

dap_v1_size EQU dap_v1_end - dap
dap_v2_size EQU dap_v2_end - dap

;
; Drive Parameter Table
;

dpt
   .buff_size	    		resw 1
   .flags			resw 1
   .cylinders			resd 1
   .heads			resd 1
   .sectors			resd 1
   .total_sectors
   .total_sectors_low 		resd 1
   .total_sectors_high 		resd 1
   .byte_count			resw 1
dpt_v1_size EQU $-dpt
.v2start
   .edd_config_parm	   	resd 1
dpt_v2_size EQU $-dpt   
.v3start
   .drive_path_sig		resw 1
   .drive_path_len		resb 1
   .reserved			resb 3
   .host_bus_asciiz		resb 4
   .interface_asciiz		resb 8
   .inteface_path		resb 8
   .device_path			resb 8
   .reserved2			resb 1
   .v3_checksum			resb 1
dpt_end
dpt_v3_size EQU $-dpt

