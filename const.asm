;******************************************************************************
; Constants for DRVTEST3
;******************************************************************************

BYTES_PER_SECTOR	EQU 	512
SECTORS_PER_TRANSFER    EQU     0x7F; (Pheonix EDD)
BUFFER_SIZE 		EQU 	BYTES_PER_SECTOR * SECTORS_PER_TRANSFER
VIDEO_BASE_SEG		EQU	0b800h
SCREEN_COLOUR		EQU	17h		; Light  Grey on Blue
STACK_SIZE		EQU     2048

