bits 16

section _TEXT class=CODE

global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
    push bp
    mov bp, sp

    push bx

    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]

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

    ; We can display the pixel using an int, the arguments
    ; (that we provided in our C program) are stored on the stack.
    mov ah, 0ch         ; Write Graphics Pixel 
    mov bh, 0           ;
    mov cx, [bp + 4]    ; first argument (pixel x)
    mov dx, [bp + 6]    ; second argument (pixel y)
    mov al, [bp + 8]    ;  argument (color)

    int 10h             ; call bios interrupt to draw a pixel

    ; restore registers
    pop bx
    mov sp, bp
    pop bp
    ret
