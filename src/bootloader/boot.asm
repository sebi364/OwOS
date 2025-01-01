; --------------------------------------------------
; Our OS uses BIOS (Legacy mode) to boot. BIOS
; starts loading the OS from 0x7C00, therfore we
; need to tell nasm to start from this address.
org 0x7C00  ; hint for nasm to start @ 0x7C00
bits 16     ; hint for nasm to assemble as 16bit

; define ascii code for return
%define NEWLINE 0x0D, 0x0A

; --------------------------------------------------
; FAT12 Headers that are required for the os to boot
; https://wiki.osdev.org/FAT#

jmp short start
nop

bdb_oem:                    db "MSWIN4.1"           ; 8B, shouldn't actually matter
bdb_bytes_per_sector:       dw 512                  ;
bdb_sectors_per_cluster:    db 1                    ;
bdb_reserved_sectors:       dw 1                    ;
bdb_fat_count:              db 2                    ;
bdb_dir_entries_count:      dw 0E0h                 ;
bdb_total_sectors:          dw 2880                 ; Total sectors (2880 Sectors * 512B = 1.44MB)
bdb_media_descriptor_type:  db 0F0h                 ; Disk type descriptor (A floppy disk in this case)
bdb_sectors_per_fat:        dw 9                    ;
bdb_sectors_per_track:      dw 18                   ;
bdb_heads:                  dw 2                    ;
bdb_hidden_sectors:         dd 0                    ;
bdb_large_sector_count:     dd 0                    ;

; EBR
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd -> useles for us
                            db 0                    ;
ebr_signature:              db 29h                  ;
ebr_volume_id:              db 31h, 13h, 70h, 69h   ; 4B Serial number, can be whatever
ebr_volume_label:           db "OwOS       "        ; 11B String, can be whatever, must be padded
ebr_system_id:              db "FAT12   "           ; 
                  

; --------------------------------------------------
; entrypoint, just jumps to our main func
; required bc main isn't our first func
start:
    jmp main

; --------------------------------------------------
; Func to read raw data from a disk.
; BIOS uses 3 values to determine from what position
; A piece of data should be read
;   - Cylinder
;   - Head
;   - Sector
; We want don't care about this, because we want to
; get the values by it's LBA Address, therfore we
; need to calculate those 3 values from an LBA:
;   - Sector    =   ($LBA / bdb_sectors_per_track) % bdb_heads
;   - Head      =   ($LBA % bdb_sectors_per_track) + 1          ; Heads start from 1, not 0
;   - Cylinder  =   ($LBA / bdb_sectors_per_track) / bdb_heads
;
; convert lba to chs
; inputs:
; - ax: LBA Address
; outputs:
; - cx[0-5]: sector number
; - cx[6-15]: cylinder number
; - dh: head number
lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bdb_sectors_per_track]
    inc dx
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]

    mov dh, dl
    mov ch, al
    shl ah, 6
    or  cl, ah

    pop ax
    mov dl, al
    pop dx

    ret

; Disk read
; Inpus:
;   - ax: LBA address
;   - cl: number of sectors to read, 128 max
;   - dl: drive number (usualy 0)
;   - ex:bx: memory address in LBA scheme
disk_read:
    push cx
    call lba_to_chs
    pop ax

    mov ah, 02h
    int 13h
    ret

; --------------------------------------------------
; print func to print a text to tty
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

; --------------------------------------------------
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

    ; call our floppy read func
    mov [ebr_drive_number], dl
    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00
    call disk_read

    ; mov address of msg_hello into msi and call print func
    ; if the disk_read func failed, we won't see this message.
    mov si, msg_hello
    call puts

    ; halt the processor
    hlt

; --------------------------------------------------
; func that runs when our code finishes.
; In this case we just loop endlessly.
.halt:
    cli         ; disable all interrupts
    jmp .halt   ; loop

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
dw 0AA55h