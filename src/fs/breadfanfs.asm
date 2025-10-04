; ===== BREADFANFS FILE SYSTEM =====
; Simple file system with directory-based metadata
; Currently stores directory only (no content storage yet)

; Initialize file system
; Clears the directory structure
fs_init:
    push di
    push cx
    push ax
    mov di, fs_directory
    mov cx, (FS_MAX_FILES * FS_ENTRY_SIZE)
    xor ax, ax
    rep stosb
    pop ax
    pop cx
    pop di
    ret

; Display file system status
fs_status:
    mov si, fs_status_msg
    mov bl, LIGHT_MAGENTA
    call print_colored
    ret

; List all files in directory
fs_list_files:
    mov si, fs_list_header
    mov bl, LIGHT_CYAN
    call print_colored
    mov bx, fs_directory
    mov cx, 0
    mov dx, 0           ; File count

fs_list_loop:
    cmp cx, FS_MAX_FILES
    jge fs_list_done
    mov al, [bx + 14]   ; Check flags byte
    test al, FILE_USED
    jz fs_list_next

    ; File is used - print it
    push bx
    push cx
    push dx
    mov si, bx
    call print_filename_simple
    mov si, fs_file_info
    mov bl, LIGHT_GRAY
    call print_colored
    pop dx
    pop cx
    pop bx
    inc dx              ; Increment file count

fs_list_next:
    add bx, FS_ENTRY_SIZE
    inc cx
    jmp fs_list_loop

fs_list_done:
    cmp dx, 0
    jne fs_list_complete
    mov si, fs_no_files
    mov bl, YELLOW
    call print_colored

fs_list_complete:
    ret

; Print filename from directory entry
; Input: SI = pointer to directory entry
print_filename_simple:
    push ax
    push cx
    push si
    mov cx, FS_FILENAME_LEN

print_name_loop:
    cmp cx, 0
    je print_name_done
    lodsb
    cmp al, 0
    je print_name_done
    cmp al, ' '
    je print_name_done
    mov ah, 0x0E
    int 0x10
    dec cx
    jmp print_name_loop

print_name_done:
    pop si
    pop cx
    pop ax
    ret

; Create test files in directory
; Called during initialization
create_test_files:
    push di
    push si
    push ax

    ; File 1: readme.txt
    mov di, fs_directory
    mov si, test_file1
    mov cx, 11
copy_file1_loop:
    lodsb
    stosb
    cmp al, 0
    je file1_name_done
    loop copy_file1_loop

file1_name_done:
    mov al, ' '
    mov cx, 1
    rep stosb
    mov byte [di], 50       ; Byte 12: start sector (low)
    inc di
    mov byte [di], 10       ; Byte 13: start sector (high)
    inc di
    mov byte [di], FILE_USED ; Byte 14: flags
    inc di
    mov byte [di], 0        ; Byte 15: sector count

    ; File 2: config.sys
    mov di, fs_directory
    add di, FS_ENTRY_SIZE
    mov si, test_file2
    mov cx, 11
copy_file2_loop:
    lodsb
    stosb
    cmp al, 0
    je file2_name_done
    loop copy_file2_loop

file2_name_done:
    mov al, ' '
    mov cx, 1
    rep stosb
    mov byte [di], 32       ; Byte 12: start sector (low)
    inc di
    mov byte [di], 11       ; Byte 13: start sector (high)
    inc di
    mov byte [di], FILE_USED ; Byte 14: flags
    inc di
    mov byte [di], 0        ; Byte 15: sector count

    pop ax
    pop si
    pop di
    ret

; Create new file (placeholder)
fs_create_file:
    mov si, fs_create_file_msg
    mov bl, YELLOW
    call print_colored
    ret
