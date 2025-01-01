; --------------------------------------------------
; Our OS uses BIOS (Legacy mode) to boot. BIOS
; starts loading the OS from 0x7C00, therfore we
; need to tell nasm to start from this address.
org 0x7C00  ; hint for nasm to start @ 0x7C00
bits 16     ; hint for nasm to assemble as 16bit

nop