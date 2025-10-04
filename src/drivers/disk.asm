; ===== DISK I/O DRIVER =====
; Low-level disk operations using BIOS int 0x13
; Uses a disk buffer at segment DISK_BUFFER_SEG

; Setup disk buffer segment in ES
setup_disk_buffer:
    push ax
    mov ax, DISK_BUFFER_SEG
    mov es, ax
    pop ax
    ret

; Clear disk buffer - fills 512 bytes with zeros
clear_disk_buffer:
    push ax
    push cx
    push di
    push es

    call setup_disk_buffer
    xor di, di
    mov cx, 512
    mov al, 0
    cld
    rep stosb

    pop es
    pop di
    pop cx
    pop ax
    ret

; Fill buffer with test pattern
fill_test_pattern:
    push ax
    push cx
    push di
    push es

    call setup_disk_buffer
    mov di, 0
    mov ch, 1           ; Pattern counter

.fill_loop:
    ; Write "TEST"
    mov al, 'T'
    mov [es:di], al
    inc di
    mov al, 'E'
    mov [es:di], al
    inc di
    mov al, 'S'
    mov [es:di], al
    inc di
    mov al, 'T'
    mov [es:di], al
    inc di

    ; Write pattern number
    mov al, '0'
    mov [es:di], al
    inc di
    mov al, ch
    add al, '0'
    mov [es:di], al
    inc di

    ; Write spaces
    mov al, ' '
    mov [es:di], al
    inc di
    mov [es:di], al
    inc di

    inc ch
    cmp di, 512
    jl .fill_loop

    pop es
    pop di
    pop cx
    pop ax
    ret

; Write test pattern to disk
write_test_pattern:
    pusha
    push es

    mov si, msg_start_write
    mov bl, WHITE
    call print_colored

    mov si, msg_filling
    mov bl, WHITE
    call print_colored
    call fill_test_pattern

    mov si, msg_filled
    mov bl, WHITE
    call print_colored

    mov si, msg_writing
    mov bl, WHITE
    call print_colored
    call write_buffer_to_disk

    pop es
    popa
    ret

; Write buffer to disk sector
; Uses TEST_SECTOR and HDD_DRIVE constants
write_buffer_to_disk:
    push ax
    push bx
    push cx
    push dx
    push es

    call setup_disk_buffer
    mov ah, 0x03        ; Write sector function
    mov al, 1           ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, TEST_SECTOR ; Sector number
    mov dh, 0           ; Head 0
    mov dl, HDD_DRIVE   ; Drive
    mov bx, 0           ; Buffer offset
    int 0x13

    jc .write_failed
    mov si, msg_write_success
    mov bl, GREEN
    call print_colored
    jmp .write_done

.write_failed:
    mov si, msg_write_error
    mov bl, RED
    call print_colored

.write_done:
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Read from disk sector
; Uses TEST_SECTOR and HDD_DRIVE constants
read_from_disk:
    pusha
    push es

    call clear_disk_buffer
    call setup_disk_buffer

    mov ah, 0x02        ; Read sector function
    mov al, 1           ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, TEST_SECTOR ; Sector number
    mov dh, 0           ; Head 0
    mov dl, HDD_DRIVE   ; Drive
    mov bx, 0           ; Buffer offset
    int 0x13

    pop es
    popa
    ret

; Debug: show first 64 bytes of disk buffer
debug_show_buffer:
    push ax
    push bx
    push cx
    push di
    push si
    push es

    call setup_disk_buffer
    mov si, debug_msg
    mov bl, YELLOW
    call print_colored

    mov cx, 64
    mov di, 0

debug_loop:
    mov al, [es:di]
    call debug_print_char
    inc di
    loop debug_loop

    mov si, newline
    mov bl, WHITE
    call print_colored

    pop es
    pop si
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Detect available drives
detect_drives:
    mov si, drives_header
    mov bl, LIGHT_CYAN
    call print_colored

    mov dl, 0x00
    call test_drive
    cmp ax, 1
    jne test_hdd
    mov si, floppy_found
    mov bl, LIGHT_GREEN
    call print_colored

test_hdd:
    mov dl, 0x80
    call test_drive
    cmp ax, 1
    jne drives_done
    mov si, hdd_found
    mov bl, LIGHT_GREEN
    call print_colored

drives_done:
    ret

; Test if a drive exists
; Input: DL = drive number
; Output: AX = 1 if drive exists, 0 if not
test_drive:
    push bx
    push cx
    push dx
    push es
    mov ah, 0x08        ; Get drive parameters
    int 0x13
    jc drive_not_found
    mov ax, 1
    jmp test_drive_done

drive_not_found:
    mov ax, 0

test_drive_done:
    pop es
    pop dx
    pop cx
    pop bx
    ret
