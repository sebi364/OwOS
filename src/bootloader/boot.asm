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
ebr_volume_id:              db 31h, 33h, 70h, 69h   ; 4B Serial number, can be whatever
ebr_volume_label:           db "OwOS       "        ; 11B String, can be whatever, must be padded
ebr_system_id:              db "FAT12   "           ; 

; --------------------------------------------------
start:
    ; setup data segments. we can't write into
    ; ds / es directly, so we need cheat it a bit.
    mov ax, 0
    mov ds, ax
    mov es, ax

    ; set stack segment to 0, and the stack-pointer
    ; to the start of our programm.
    mov ss, ax
    mov sp, 0x7C00

    ; some BIOSes might start us at 07C0:0000 instead of 0000:7C00, make sure we are in the
    ; expected location
    push es
    push word .after
    retf

    .after:
        ; read something from floppy disk
        ; BIOS should set DL to drive number
        mov [ebr_drive_number], dl

        ; show loading message
        mov si, msg_loading
        call puts

        ; read drive parameters (sectors per track and head count),
        ; instead of relying on data on formatted disk
        push es
        mov ah, 08h
        int 13h
        jc floppy_error
        pop es

        and cl, 0x3F                        ; remove top 2 bits
        xor ch, ch
        mov [bdb_sectors_per_track], cx     ; sector count

        inc dh
        mov [bdb_heads], dh                 ; head count

        ; compute LBA of root directory = reserved + fats * sectors_per_fat
        ; note: this section can be hardcoded
        mov ax, [bdb_sectors_per_fat]
        mov bl, [bdb_fat_count]
        xor bh, bh
        mul bx                              ; ax = (fats * sectors_per_fat)
        add ax, [bdb_reserved_sectors]      ; ax = LBA of root directory
        push ax

        ; compute size of root directory = (32 * number_of_entries) / bytes_per_sector
        mov ax, [bdb_dir_entries_count]
        shl ax, 5                           ; ax *= 32
        xor dx, dx                          ; dx = 0
        div word [bdb_bytes_per_sector]     ; number of sectors we need to read

        test dx, dx                         ; if dx != 0, add 1
        jz .root_dir_after
        inc ax  

    .root_dir_after:
        mov cl, al                  ; cl = number of sectors to read
        pop ax                      ; ax = LBA of root directory
        mov dl, [ebr_drive_number]  ; dl = drive_number
        mov bx, buffer              ; es:bx = buffer
        call disk_read

        ; search for kernel.bin
        xor bx, bx
        mov di, buffer

    .search_kernel:
        mov si, file_kernel_bin     ; filename
        mov cx, 11                  ; compare up to 11 chars
        push di
        ; repeat
        ;   compare string bytes
        ; up to cx times
        repe cmpsb
        pop di

        je .found_kernel

        ; check if we are through all entries
        add di, 32
        inc bx
        cmp bx,[bdb_dir_entries_count]
        jl .search_kernel

        jmp kernel_not_found_error
    
    .found_kernel:
        ; di stil holds the address of the directory
        mov ax, [di + 26]
        mov [kernel_cluster], ax

        ; load FAT from disk into memory
        mov ax, [bdb_reserved_sectors]
        mov bx, buffer
        mov cl, [bdb_sectors_per_fat]
        mov dl, [ebr_drive_number]
        call disk_read

        ; read kernel and process FAT chain
        mov bx, KERNEL_LOAD_SEGMENT
        mov es, bx
        mov bx, KERNEL_LOAD_OFFSET
    
    .load_kernel_loop:
        ; read next cluster
        mov ax, [kernel_cluster]

        add ax, 31
        mov cl, 1
        mov dl, [ebr_drive_number]
        call disk_read

        add bx, [bdb_bytes_per_sector]

        ; compute location of next cluster
        mov ax, [kernel_cluster]
        mov cx, 3
        mul cx
        mov cx, 2
        div cx

        mov si, buffer
        add si, ax
        mov ax, [ds:si]

        or dx, dx
        jz .even
    
    .odd:
        shr ax, 4
        jmp .next_cluster_after
    
    .even:
        and ax, 0x0FFF
    
    .next_cluster_after:
        cmp ax, 0x0FF8
        jae .read_finish

        mov [kernel_cluster], ax
        jmp .load_kernel_loop

    .read_finish:
        mov dl, [ebr_drive_number]
        mov ax, KERNEL_LOAD_SEGMENT
        mov ds, ax
        mov es, ax

        jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

; --------------------------------------------------
; print func to print a text to tty
; reads string untill it encounters a NULL char
; inputs:
;   - ds:si
puts:
    ; save registers we will modify
    push si
    push ax
    push bx

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
        pop bx
        pop ax
        pop si
        ret

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
    pop ax

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
; Error handlers
.halt:
    cli         ; disable all interrupts
    jmp .halt   ; loop

kernel_not_found_error:
    mov si, msg_kernel_not_found
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                     ; wait for keypress
    jmp 0FFFFh:0                ; jump to beginning of BIOS, should reboot

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

; --------------------------------------------------
; string followed by an newline character and a NULL
msg_kernel_not_found: db "No kernel found in root directory!", NEWLINE, 0
file_kernel_bin: db "KERNEL  BIN", NEWLINE, 0
msg_read_failed: db 'Read from disk failed!', NEWLINE, 0
msg_loading:            db 'Loading...', NEWLINE, 0

; misc variables & definitions
kernel_cluster: db 0
KERNEL_LOAD_SEGMENT: equ 0x2000
KERNEL_LOAD_OFFSET: equ 0

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

buffer: