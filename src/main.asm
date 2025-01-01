; --------------------------------------------------
; Our OS uses BIOS (Legacy mode) to boot. BIOS
; starts loading the OS from 0x7C00, therfore we
; need to tell nasm to start from this address.
org 0x7C00  ; hint for nasm to start @ 0x7C00
bits 16     ; hint for nasm to assemble as 16bit

; define ascii code for return
%define NEWLINE 0x0D, 0x0A

; entrypoint, just jumps to our main func
; required bc main isn't our first func
start:
    jmp main

; --------------------------------------------------
; print function to print a text to tty
; reads string untill it encounters a NULL char
; inputs:
;   - ds:si
puts:
    ; save registers we will modify
    push si
    push ax

    .loop:
        lodsb       ; load next char in al
        or al, al   ; check if null -> will set zeru flag
        jz .done    ; if zero flag -> finished

        ; Trigger BIOS interrupt to print char to tty.
        ; http://vitaly_filatov.tripod.com/ng/asm/asm_023.15.html
        mov ah, 0x0e
        mov bh, 0
        int 0x10

        jmp .loop   ; turn the loop into a loop

    .done:
        ; restore registers & exit func
        pop ax
        pop si
        ret

main:
    ; setup data segments. we can't write into
    ; ds / es directly, so we need cheat it a bit.
    mov ax, 0
    mov ds, ax
    mov es, ax

    ; set stack segment to 0, and the stack-pointer
    ; to the start of our programm.
    mov ss, ax
    mov sp, 0x7C00

    ; mov address of msg_hello into msi and call print func
    mov si, msg_hello
    call puts

; --------------------------------------------------
; Function that runs when our code finishes.
; In this case we just loop endlessly.
.halt:
    jmp .halt

; --------------------------------------------------
; string followed by an newline character and a NULL
msg_hello db "Hello World!", NEWLINE, 0

; --------------------------------------------------
; In order for our OS to be recognized by
; the BIOS, our last two bytes must have
; the signature 0AA55H.

; first we use the DB (Define Bytes) Instruction
; to tell nasm that it should fill up the remaining
; space with zeros

; $ -> Memory position of current line
; $$ -> Memory position of current section
; 510 -> Block size - 2 Bytes for signature
; $-$$ -> Program size atm in Bytes
times 510-($-$$) db 0

; finally, we add the signature
dw 0AA55H