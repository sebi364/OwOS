bits 16
section _ENTRY class=CODE

extern _cstart_
global entry

entry:
    cli
    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp
    sti

    mov ah, 0x00       ; Function to set video mode
    mov al, 0x13       ; 0x13 = 640x480, 16 colors
    int 0x10           ; Call BIOS interrupt

    xor dh, dh
    push dx
    call _cstart_

    cli
    hlt