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

    ; The BIOS has 2 modef for a graphical output:
    ; - 0x12 (640x480, 16 colors)
    ; - 0x13 (320x200, 256 colors)
    ; We use the second one, because it's easier
    ; to work with. It can be enabled using a 
    ; BIOS interrupt.
    mov ah, 0x00       ; Function to set video mode
    mov al, 0x13       ; 0x13 = 640x480, 16 colors
    int 0x10           ; Call BIOS interrupt

    ; Jump to start of compiled C executable
    xor dh, dh
    push dx
    call _cstart_

    cli
    hlt