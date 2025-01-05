bits 16

section _TEXT class=CODE

global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
    push bp
    mov bp, sp

    push bx

    mov ah, 0Eh
    mov al, [bp + 2]
    mov bh, [bp + 4]

    int 10h

    pop bx

    mov sp, bp
    pop bp
    ret

global _x86_Video_WritePixelVideo
_x86_Video_WritePixelVideo:
    ; store registers we will use on the stack
    push bp
    mov bp, sp
    push bx

    mov ah, 0ch
    mov bh, 0
    mov cx, [bp + 4] ; move first argument (pixel x) to dx
    mov dx, [bp + 6] ; move second argument (pixel y) to cx
    mov al, [bp + 8] ; move third argument (color) to al

    int 10h     ; call bios interrupt to draw a pixel

    ; restore registers
    pop bx
    mov sp, bp
    pop bp
    ret
