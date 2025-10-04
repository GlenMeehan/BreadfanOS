; ===== BREADFANFS MODULE =====
; File system with content storage support

; ===== FILE SYSTEM STRUCTURE =====
; Directory Entry (32 bytes each):
; Offset 0-11:  Filename (12 bytes, null-terminated)
; Offset 12-13: File size in bytes (word)
; Offset 14-15: Starting sector (word)
; Offset 16-17: Number of sectors (word)
; Offset 18:    Flags (1 byte) - bit 0: file exists
; Offset 19-31: Reserved (13 bytes)

; File data storage starts at sector 100
; Each file can use multiple consecutive sectors

; Initialize file system
fs_init:
    pusha
    ; Clear directory area in memory
    mov di, fs_directory
    mov cx, (FS_MAX_FILES * FS_ENTRY_SIZE)
    xor al, al
    rep stosb
    popa
    ret

; Create test files (for demonstration)
create_test_files:
    pusha
    ; Create readme.txt
    mov si, test_file1
    mov di, fs_directory
    call copy_filename
    ; Create config.sys
    mov si, test_file2
    mov di, fs_directory + FS_ENTRY_SIZE
    call copy_filename
    popa
    ret

; Copy filename to directory entry
; SI = source filename, DI = directory entry
copy_filename:
    push cx
    mov cx, 12
.copy_loop:
    lodsb
    stosb
    test al, al
    jz .done
    loop .copy_loop
.done:
    pop cx
    ret

; List all files in directory
fs_list_files:
    pusha
    mov si, fs_list_header
    mov bl, LIGHT_CYAN
    call print_colored

    mov di, fs_directory
    mov cx, FS_MAX_FILES

.list_loop:
    ; Check if file exists (flags byte)
    mov al, [di + 18]
    test al, 1
    jz .skip_file

    ; Check if filename is not empty
    cmp byte [di], 0
    je .skip_file

    ; Print filename
    push di
    mov si, di
    mov bl, WHITE
    call print_colored

    ; Print file info (size and sector)
    mov si, fs_file_detail
    mov bl, LIGHT_GRAY
    call print_colored

    pop di

    ; Print file size
    mov ax, [di + 12]
    call print_number

    mov si, bytes_msg
    mov bl, LIGHT_GRAY
    call print_colored

    ; Print starting sector
    mov ax, [di + 14]
    call print_number

    mov si, sector_msg
    mov bl, LIGHT_GRAY
    call print_colored

    mov si, newline_str
    call print_colored

.skip_file:
    add di, FS_ENTRY_SIZE
    loop .list_loop

    popa
    ret

; Display file system status
fs_status:
    mov si, fs_status_msg
    mov bl, LIGHT_GREEN
    call print_colored
    ret

; Create a new file
; Input: command_buffer contains "makefile <filename>"
fs_create_file:
    pusha

    ; Extract filename from command
    call extract_first_word  ; Skip "makefile"

    ; Get the actual filename (second word)
    mov si, command_buffer
    add si, 9  ; Skip past "makefile "

    ; Find first empty directory entry
    mov di, fs_directory
    mov cx, FS_MAX_FILES

.find_empty:
    cmp byte [di], 0
    je .found_empty
    add di, FS_ENTRY_SIZE
    loop .find_empty

    ; No space available
    mov si, fs_no_space_msg
    mov bl, LIGHT_RED
    call print_colored
    jmp .done

.found_empty:
    ; Copy filename to directory entry
    push di
    mov cx, 12
.copy_name:
    lodsb
    cmp al, 0
    je .name_done
    cmp al, ' '
    je .name_done
    cmp al, 13
    je .name_done
    stosb
    loop .copy_name

.name_done:
    mov al, 0
    stosb
    pop di

    ; Set file exists flag
    mov byte [di + 18], 1

    ; Initialize other fields to zero
    mov word [di + 12], 0  ; Size = 0
    mov word [di + 14], 0  ; Start sector = 0 (allocated on write)
    mov word [di + 16], 0  ; Num sectors = 0

    mov si, fs_create_file_msg
    mov bl, LIGHT_GREEN
    call print_colored

.done:
    popa
    ret

; Find file by name
; Input: SI = filename to search for
; Output: DI = directory entry pointer (or 0 if not found), CF = set if found
fs_find_file:
    push cx
    push si
    push ax

    mov di, fs_directory
    mov cx, FS_MAX_FILES

.search_loop:
    ; Check if entry exists
    mov al, [di + 18]
    test al, 1
    jz .next_entry

    ; Compare filenames
    push si
    push di
    mov cx, 12
.compare:
    lodsb
    cmp al, [di]
    jne .not_match
    inc di
    test al, al
    jz .match
    loop .compare

.match:
    pop di
    pop si
    stc  ; Set carry flag (found)
    jmp .done

.not_match:
    pop di
    pop si

.next_entry:
    add di, FS_ENTRY_SIZE
    loop .search_loop

    ; Not found
    xor di, di
    clc  ; Clear carry flag (not found)

.done:
    pop ax
    pop si
    pop cx
    ret

; Allocate sectors for a file
; Input: AX = number of bytes needed
; Output: BX = starting sector, CF = set on success
fs_allocate_sectors:
    push ax
    push cx
    push dx

    ; Convert bytes to sectors (round up)
    add ax, 511
    mov cx, 512
    xor dx, dx
    div cx  ; AX = number of sectors needed

    ; For now, simple allocation: find highest used sector + 1
    ; In a real system, you'd maintain a free sector bitmap
    mov bx, 100  ; Start from sector 100

    ; TODO: Implement proper sector allocation tracking
    ; For now, just return next available sector

    stc  ; Success

    pop dx
    pop cx
    pop ax
    ret

; Write content to file
; Input: SI = filename, DI = content buffer, CX = content length
; Output: CF = set on success
fs_write_file:
    push ax
    push bx
    push cx
    push dx
    push di
    push si

    push si  ; Save filename pointer
    push cx  ; Save content length

    ; Find the file
    call fs_find_file
    jc .file_exists

    ; File doesn't exist - create it
    ; Find first empty directory entry
    mov di, fs_directory
    mov cx, FS_MAX_FILES

.find_empty:
    mov al, [di + 18]  ; Check exists flag
    test al, 1
    jz .found_empty
    add di, FS_ENTRY_SIZE
    loop .find_empty

    ; No space available
    pop cx
    pop si
    clc
    jmp .done

.found_empty:
    ; Copy filename to directory entry
    pop cx  ; Get content length back
    pop si  ; Get filename back
    push si
    push cx
    push di

    ; Copy filename
    mov cx, 12
.copy_name:
    lodsb
    stosb
    test al, al
    jz .name_copied
    loop .copy_name

.name_copied:
    pop di

    ; Set file exists flag
    mov byte [di + 18], 1

    jmp .file_ready

.file_exists:
    ; DI already points to directory entry

.file_ready:
    pop cx  ; Restore content length
    pop si  ; Restore filename (but we don't need it anymore)

    push di

    ; Allocate sectors if needed
    mov ax, cx  ; Content length
    call fs_allocate_sectors
    ; BX = starting sector

    pop di

    ; Update directory entry
    mov [di + 12], cx  ; File size
    mov [di + 14], bx  ; Starting sector

    ; Calculate number of sectors
    push cx
    mov ax, cx
    add ax, 511
    mov cx, 512
    xor dx, dx
    div cx
    mov [di + 16], ax  ; Number of sectors
    pop cx

    ; Write content to disk
    ; For now, content stays in memory (content_buffer)
    ; TODO: Implement actual disk write

    stc  ; Success

.done:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Read content from file
; Input: SI = filename
; Output: DI = content buffer, CX = content length, CF = set on success
fs_read_file:
    push ax
    push bx
    push dx
    push si

    ; Find the file
    call fs_find_file
    jnc .file_not_found

    ; DI now points to directory entry
    mov cx, [di + 12]  ; File size
    test cx, cx
    jz .empty_file

    mov bx, [di + 14]  ; Starting sector

    ; Read from disk into content_buffer
    mov di, content_buffer

    ; TODO: Implement actual disk read
    ; For now, just mark as success

    stc
    jmp .done

.empty_file:
.file_not_found:
    xor cx, cx
    clc

.done:
    pop si
    pop dx
    pop bx
    pop ax
    ret

; Helper: Print a number in decimal
print_number:
    pusha
    mov di, temp_buffer
    call int_to_str
    mov si, temp_buffer
    mov bl, WHITE
    call print_colored
    popa
    ret
