; ===== BREADFANOS KERNEL - REFACTORED VERSION =====
; Improved with helper functions to eliminate repetition

[org 0x7E00]
[bits 16]

; ===== COLOR CONSTANTS =====
%define BLACK 0
%define BLUE 1
%define GREEN 2
%define CYAN 3
%define RED 4
%define MAGENTA 5
%define BROWN 6
%define LIGHT_GRAY 7
%define DARK_GRAY 8
%define LIGHT_BLUE 9
%define LIGHT_GREEN 10
%define LIGHT_CYAN 11
%define LIGHT_RED 12
%define LIGHT_MAGENTA 13
%define YELLOW 14
%define WHITE 15

; ===== FILE SYSTEM CONSTANTS =====
%define FS_MAX_FILES 8
%define FS_FILENAME_LEN 12
%define FS_ENTRY_SIZE 16
%define FILE_USED 0x01

; ===== I/O CONSTANTS =====
DISK_BUFFER_SEG equ 0x1000
HDD_DRIVE equ 0x81
TEST_SECTOR equ 50

; ===== KERNEL ENTRY POINT =====
kernel_start:
    call clear_screen
    call fs_init
    call create_test_files
    call show_welcome
    call show_system_info

main_shell_loop:
    call show_prompt
    call read_command
    call process_command
    jmp main_shell_loop

; ===== HELPER FUNCTIONS =====

scroll_up:
    pusha
    mov ah, 6           ; BIOS scroll up function
    mov al, 1           ; scroll 1 line
    mov bh, 7           ; normal attribute (white on black)
    mov cx, 0           ; top-left corner (row 0, col 0)
    mov dx, 184Fh       ; bottom-right (row 24, col 79)
    int 0x10

    ; Move cursor to start of bottom line
    mov ah, 2           ; set cursor position
    mov bh, 0           ; page 0
    mov dh, 24          ; row 24 (bottom line)
    mov dl, 0           ; column 0
    int 0x10
    popa
    ret

; NEW: Universal command checker - eliminates repetitive strcmp calls
check_command:
    ; Input: SI=command_buffer, DI=command_string
    ; Output: Zero flag set if match, clear if no match
    push ax
    call strcmp
    test ax, ax         ; Set zero flag if AX=0 (match)
    pop ax
    ret

; Extract first word from command_buffer into first_word_buffer
extract_first_word:
    push si
    push di
    push ax

    mov si, command_buffer
    mov di, first_word_buffer

.extract_loop:
    mov al, [si]
    cmp al, ' '         ; stop at space
    je .word_done
    cmp al, 0           ; stop at null terminator
    je .word_done
    cmp al, 9           ; stop at tab
    je .word_done

    mov [di], al        ; copy character
    inc si
    inc di
    jmp .extract_loop

.word_done:
    mov byte [di], 0    ; null terminate first word

    pop ax
    pop di
    pop si
    ret

; NEW: Setup disk buffer segment - used by all disk I/O functions
setup_disk_buffer:
    push ax
    mov ax, DISK_BUFFER_SEG
    mov es, ax
    pop ax
    ret

; NEW: Clear disk buffer - fills 512 bytes with zeros
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

; NEW: Fill buffer with test pattern - extracted from write function
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

; Number parsing functions for BreadfanOS calculator
; Add these functions to your kernel

; Convert string to integer
; Input: SI = pointer to null-terminated string
; Output: AX = integer value, CF = 1 if error
; ---------------------------
; str_to_int - parse unsigned decimal integer
; Input:  SI -> NUL-terminated (or space-terminated) string (pointer into command_buffer)
; Output: AX = parsed value (0..65535)
;         CF = 0 on success (at least one digit parsed), CF = 1 on error (no digits)
; Side effects: SI is advanced to first non-digit (space/operator/etc.)
; Preserves: BX, CX, DX
; ---------------------------
str_to_int:
    push bx
    push cx
    push dx

    xor ax, ax        ; result = 0
    xor cx, cx        ; digit count = 0
    xor bx, bx
    cld

.str_loop:
    mov bl, [si]
    test bl, bl
    jz .done_if_any   ; end of string -> ok if digits were read
    cmp bl, '0'
    jb .done_if_any   ; not a digit -> done (if none read, error)
    cmp bl, '9'
    ja .done_if_any   ; not a digit -> done
    ; it's a digit
    sub bl, '0'       ; numeric value 0..9
    ; multiply AX by 10: AX = AX*10
    mov dx, ax
    shl ax, 3         ; AX = AX * 8
    add ax, dx        ; AX = AX*9
    add ax, dx        ; AX = AX*10 (using DX as temp)
    add ax, bx        ; AX += digit
    inc si
    inc cx
    jmp .str_loop

.done_if_any:
    cmp cx, 0
    jne .success
    ; no digits parsed -> error
    stc
    xor ax, ax
    pop dx
    pop cx
    pop bx
    ret

.success:
    clc
    pop dx
    pop cx
    pop bx
    ret

.error:
    popa
    xor ax, ax          ; return 0
    stc                 ; set carry flag (error)
    ret

; Convert integer to string
; Input: AX = integer value, DI = pointer to buffer
; Output: String stored at DI
; ---------------------------
; int_to_str - convert unsigned AX to ASCII string at DI
; Input:  AX = value, DI -> buffer (must have enough space)
; Output: buffer filled with ascii digits and terminated with 0
; Preserves: BX,CX,DX
; ---------------------------
int_to_str:
    push bx
    push cx
    push dx


    cmp ax, 0
    jne .conv
    mov byte [di], '0'
    mov byte [di+1], 0
    jmp .done

.conv:
    mov bx, 10
    xor cx, cx      ; digits counter
    ; We'll push digits on stack (low bytes) then pop to buffer
.conv_loop:
    xor dx, dx
    div bx          ; AX = AX/10, DX = remainder (0..9)
    push dx         ; push remainder (16-bit) -> low byte contains digit
    inc cx
    test ax, ax
    jnz .conv_loop

.store_digits:
    pop dx
    add dl, '0'
    mov [di], dl
    inc di
    dec cx
    jnz .store_digits

    mov byte [di], 0

.done:
    pop dx
    pop cx
    pop bx
    ret

; Test the number parsing
test_number_parsing:
    push si
    push di

    ; Show original string
    mov si, original_msg
    call print_colored
    mov si, test_string_123
    call print_colored
    mov si, newline_str
    call print_colored

    ; Test str_to_int with "123"
    mov si, test_string_123
    call str_to_int
    jc .test_failed

    ; Show the integer value (we'll display it as converted back)
    mov si, converted_msg
    call print_colored

    ; Convert back to string to verify
    mov di, temp_buffer
    call int_to_str

    ; Print result
    mov si, temp_buffer
    call print_colored
    mov si, newline_str
    call print_colored

    pop di
    pop si
    ret

.test_failed:
    mov si, parse_error_msg
    call print_colored
    pop di
    pop si
    ret


; Simple calculator for BreadfanOS
; Handles: calc 5 + 3, calc 10 - 2, calc 6 * 4, calc 20 / 5

; Main calculator function - call this from your command processor
calculator:
    pusha

    ; Skip past "calc " (5 characters)
    mov si, command_buffer
    add si, 5           ; move past "calc "

    ; Parse first number
    call skip_whitespace
    call str_to_int
    jc .calc_error      ; if conversion failed
    mov [first_number], ax

    ; Parse operator
    call skip_whitespace
    mov al, [si]        ; get operator character
    mov [operator], al
    inc si              ; move past operator

    ; Validate operator
    cmp al, '+'
    je .valid_op
    cmp al, '-'
    je .valid_op
    cmp al, '*'
    je .valid_op
    cmp al, '/'
    je .valid_op
    jmp .calc_error     ; invalid operator

.valid_op:
    ; Parse second number
    call skip_whitespace
    call str_to_int
    jc .calc_error      ; if conversion failed
    mov [second_number], ax

    ; Perform calculation
    call do_calculation
    jc .calc_error      ; if calculation failed (e.g., divide by zero)

    ; Display result
    mov si, result_msg
    call print_colored
    mov di, temp_buffer
    call int_to_str
    mov si, temp_buffer
    call print_colored
    mov si, newline_str
    call print_colored

    popa
    ret

.calc_error:
    mov si, error_msg
    call print_colored
    popa
    ret

; Skip whitespace characters (space, tab)
skip_whitespace:
    push ax
.skip_loop:
    mov al, [si]
    cmp al, ' '         ; space
    je .skip_char
    cmp al, 9           ; tab
    je .skip_char
    pop ax
    ret                 ; no more whitespace
.skip_char:
    inc si
    jmp .skip_loop

; Perform the actual calculation
do_calculation:
    pusha

    mov ax, [first_number]
    mov bx, [second_number]
    mov cl, [operator]

    cmp cl, '+'
    je .do_add
    cmp cl, '-'
    je .do_sub
    cmp cl, '*'
    je .do_mul
    cmp cl, '/'
    je .do_div

    ; Should never reach here due to validation
    stc                 ; set carry flag for error
    popa
    ret

.do_add:
    add ax, bx
    jmp .calc_done

.do_sub:
    sub ax, bx
    jmp .calc_done

.do_mul:
    mul bx              ; result in AX
    jmp .calc_done

.do_div:
    test bx, bx         ; check for division by zero
    jz .div_error
    xor dx, dx          ; clear dx for division
    div bx              ; result in AX
    jmp .calc_done

.div_error:
    stc                 ; set carry flag for error
    popa
    ret

.calc_done:
    mov [calc_result], ax
    clc                 ; clear carry flag (success)
    popa
    mov ax, [calc_result]
    ret

; ===== SYSTEM INFO =====
show_system_info:
    mov si, system_info_msg
    mov bl, LIGHT_CYAN
    call print_colored
    ret

; ===== SHELL MODULE =====
show_welcome:
    mov si, welcome_msg
    mov bl, LIGHT_CYAN
    call print_colored
    ret

show_prompt:
    mov si, prompt_msg
    mov bl, YELLOW
    call print_colored
    ret

read_command:
    mov di, command_buffer
    mov cx, 0

read_loop:
    call wait_for_key
    cmp al, 13
    je read_done
    cmp al, 8
    je handle_backspace
    cmp al, 32
    jl read_loop
    cmp al, 126
    jg read_loop
    cmp cx, 63
    jge read_loop

    stosb
    inc cx
    push si
    mov si, temp_char
    mov [temp_char], al
    mov bl, LIGHT_GRAY
    call print_colored
    pop si
    jmp read_loop

handle_backspace:
    test cx, cx
    jz read_loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp read_loop

read_done:
    mov al, 0
    stosb
    mov si, newline
    mov bl, LIGHT_GRAY
    call print_colored
    ret

; ===== IMPROVED COMMAND PROCESSING =====
process_command:
    mov si, command_buffer

    ; Use the new check_command helper function
    mov di, cmd_help
    call check_command
    jz cmd_help_handler

    mov si, command_buffer
    mov di, cmd_clear
    call check_command
    jz cmd_clear_handler

    mov si, command_buffer
    mov di, cmd_hello
    call check_command
    jz cmd_hello_handler

    mov si, command_buffer
    mov di, cmd_info
    call check_command
    jz cmd_info_handler

    mov si, command_buffer
    mov di, cmd_ls
    call check_command
    jz cmd_ls_handler

    mov si, command_buffer
    mov di, cmd_fs
    call check_command
    jz cmd_fs_handler

    mov si, command_buffer
    mov di, cmd_exit
    call check_command
    jz cmd_exit_handler

    mov si, command_buffer
    mov di, cmd_writet
    call check_command
    jz cmd_writet_handler

    mov si, command_buffer
    mov di, cmd_readd
    call check_command
    jz cmd_readd_handler

    mov si, command_buffer
    mov di, cmd_debug
    call check_command
    jz cmd_debug_handler

    mov si, command_buffer
    mov di, cmd_makefile
    call check_command
    jz cmd_makefile_handler

    mov si, command_buffer
    mov di, cmd_drives
    call check_command
    jz cmd_drives_handler

    mov si, command_buffer
    mov di, cmd_calc_test
    call check_command
    jz cmd_test_number_parsing_handler

    call extract_first_word     ; Extract "calc" from "calc 5 + 3"
    mov si, first_word_buffer   ; Now compare just "calc"
   mov di, calc_cmd
   call check_command
   jz calculator

    ; Check for empty command
    mov si, command_buffer
    cmp byte [si], 0
    je process_done

    ; Unknown command
    mov si, unknown_msg
    mov bl, LIGHT_RED
    call print_colored

process_done:
    ret

; ===== COMMAND HANDLERS =====
cmd_help_handler:
    mov si, help_msg
    mov bl, WHITE
    call print_colored
    ret

cmd_clear_handler:
    call clear_screen
    ret

cmd_hello_handler:
    mov si, hello_msg
    mov bl, LIGHT_GREEN
    call print_colored
    ret

cmd_info_handler:
    mov si, info_msg
    mov bl, LIGHT_BLUE
    call print_colored
    ret

cmd_ls_handler:
    call fs_list_files
    ret

cmd_fs_handler:
    call fs_status
    ret

cmd_makefile_handler:
    call fs_create_file
    ret

cmd_drives_handler:
    call detect_drives
    ret

cmd_writet_handler:
    call write_test_pattern
    ret

cmd_readd_handler:
    call read_from_disk
    ret

cmd_debug_handler:
    call debug_show_buffer
    ret

cmd_test_number_parsing_handler:
    call test_number_parsing
    ret

cmd_exit_handler:
    mov si, goodbye_msg
    mov bl, YELLOW
    call print_colored
    mov si, safe_to_close_msg
    mov bl, LIGHT_GREEN
    call print_colored
    cli
    hlt

safe_to_close_msg:
    db 'System halted - safe to power-off.', 10, 0

; ===== STRING UTILITIES =====
strcmp:
    push si
    push di

strcmp_loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne strcmp_not_equal
    test al, al
    jz strcmp_equal
    inc si
    inc di
    jmp strcmp_loop

strcmp_equal:
    xor ax, ax
    jmp strcmp_done

strcmp_not_equal:
    mov ax, 1

strcmp_done:
    pop di
    pop si
    ret

; ===== DISPLAY MODULE =====
print_colored:
    pusha

print_colored_loop:
    lodsb
    test al, al
    jz print_colored_done
    cmp al, 10
    je handle_newline_colored
    mov ah, 0x09
    mov bh, 0
    mov cx, 1
    int 0x10
    call advance_cursor
    jmp print_colored_loop

print_colored_done:
    popa
    ret

clear_screen:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov dh, 0
    mov dl, 0
    call set_cursor
    ret

handle_newline_colored:
    call get_cursor

    ; Add scroll check here
    cmp dh, 24          ; are we on bottom row (row 24)?
    jl .normal_newline  ; if not, do normal newline

    ; We're at bottom - scroll instead of moving to next line
    call scroll_up
    jmp print_colored_loop  ; continue printing, cursor already positioned

.normal_newline:
    ; Your existing newline handling
    inc dh
    mov dl, 0
    call set_cursor
    jmp print_colored_loop

; ===== CURSOR MODULE =====
set_cursor:
    push ax
    push bx
    mov ah, 0x02
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret

get_cursor:
    push ax
    push bx
    mov ah, 0x03
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret

advance_cursor:
    push ax
    push bx
    push dx
    call get_cursor
    inc dl
    cmp dl, 80
    jl advance_done
    mov dl, 0
    inc dh
    cmp dh, 25
    jl advance_done
    mov dh, 24

advance_done:
    call set_cursor
    pop dx
    pop bx
    pop ax
    ret

; ===== INPUT MODULE =====
wait_for_key:
    mov ah, 0x00
    int 0x16
    ret

; ===== SIMPLIFIED I/O FUNCTIONS =====

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

write_buffer_to_disk:
    push ax
    push bx
    push cx
    push dx
    push es

    call setup_disk_buffer
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, TEST_SECTOR
    mov dh, 0
    mov dl, HDD_DRIVE
    mov bx, 0
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

read_from_disk:
    pusha
    push es

    call clear_disk_buffer
    call setup_disk_buffer

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, TEST_SECTOR
    mov dh, 0
    mov dl, HDD_DRIVE
    mov bx, 0
    int 0x13

    pop es
    popa
    ret

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

debug_print_char:
    push ax
    push bx
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret

; ===== FILE SYSTEM MODULE =====
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

fs_status:
    mov si, fs_status_msg
    mov bl, LIGHT_MAGENTA
    call print_colored
    ret

fs_list_files:
    mov si, fs_list_header
    mov bl, LIGHT_CYAN
    call print_colored
    mov bx, fs_directory
    mov cx, 0
    mov dx, 0

fs_list_loop:
    cmp cx, FS_MAX_FILES
    jge fs_list_done
    mov al, [bx + 14]
    test al, FILE_USED
    jz fs_list_next
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
    inc dx

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

create_test_files:
    push di
    push si
    push ax

    ; File 1
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
    mov byte [di], 50
    inc di
    mov byte [di], 10
    inc di
    mov byte [di], FILE_USED
    inc di
    mov byte [di], 0

    ; File 2
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
    mov byte [di], 32
    inc di
    mov byte [di], 11
    inc di
    mov byte [di], FILE_USED
    inc di
    mov byte [di], 0

    pop ax
    pop si
    pop di
    ret

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

test_drive:
    push bx
    push cx
    push dx
    push es
    mov ah, 0x08
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

fs_create_file:
    mov si, fs_create_file__msg
    mov bl, YELLOW
    call print_colored
    ret

; ===== DATA SECTION =====
welcome_msg:
    db 'BreadfanOS Shell v2.0 - Now with 4 sectors!', 10
    db 'Type "help" for available commands.', 10, 10, 0

system_info_msg:
    db 'System: 4-sector kernel (2048 bytes)', 10
    db 'Memory: 0x7E00-0x86FF', 10, 10, 0

prompt_msg:
    db 'BreadfanOS>>', 0

newline:
    db 10, 0

temp_char:
    db 0, 0

help_msg:
    db 'Available commands:', 10
    db '  clear  - Clear the screen', 10
    db '  drives - Detect available drives', 10
    db '  exit   - Shutdown system', 10
    db '  fs     - File system status', 10
    db '  hello  - Display greeting', 10
    db '  help   - Show this help', 10
    db '  info   - Show system information', 10
    db '  ls     - List files', 10
    db '  writet - Write test to hdd', 10
    db '  readd - Read from hdd', 10
    db '  debug - Show buffer contents', 10
    db '  numtest - Test string parsing', 10
    db '  makefile - Create new file', 10, 0

hello_msg:
    db 'Hello from BreadfanOS v2.0!', 10, 0

info_msg:
    db 'BreadfanOS Kernel Information:', 10
    db 'Version: 2.0 (4-sector)', 10
    db 'Architecture: x86 16-bit', 10
    db 'Kernel Size: 2048 bytes (4 sectors)', 10
    db 'Available Commands: 12', 10
    db 'File System: BreadfanFS initialized', 10, 0

goodbye_msg:
    db 'Thanks for using BreadfanOS! Shutting down...', 10, 0

unknown_msg:
    db 'Unknown command. Type "help" for available commands.', 10, 0

fs_status_msg:
    db 'BreadfanFS Status:', 10
    db 'Type: Custom modern file system', 10
    db 'Max Files: 8', 10
    db 'Filename Length: 12 characters', 10
    db 'Features: Directory listing (Phase 1)', 10, 0

fs_list_header:
    db 'Directory listing:', 10, 0

fs_file_info:
    db ' [file]', 10, 0

fs_no_files:
    db 'No files found.', 10, 0

fs_create_file__msg:
    db 'New file created.', 10, 0

drives_header:
    db 'Detecting available drives...', 10, 0

floppy_found:
    db 'Drive 0x00: Floppy disk detected', 10, 0

hdd_found:
    db 'Drive 0x80: Hard disk detected', 10, 0

; Command strings
cmd_help:           db 'help', 0
cmd_makefile:       db 'makefile', 0
cmd_drives:         db 'drives', 0
cmd_clear:          db 'clear', 0
cmd_hello:          db 'hello', 0
cmd_info:           db 'info', 0
cmd_ls:             db 'ls', 0
cmd_fs:             db 'fs', 0
cmd_exit:           db 'exit', 0
cmd_writet:         db 'writet', 0
cmd_readd:          db 'readd', 0
cmd_calc_test:       db 'numtest', 0
calc_cmd:                db 'calc', 0
cmd_debug:          db 'debug', 0

command_buffer: times 64 db 0
first_word_buffer: times 32 db 0    ; buffer for extracted first word

fs_directory: times (FS_MAX_FILES * FS_ENTRY_SIZE) db 0

test_file1: db 'readme.txt', 0
test_file2: db 'config.sys', 0

; I/O Messages
msg_start_write:     db 'Starting disk write test...', 13, 10, 0
msg_filling:         db '1. Filling buffer with test pattern...', 13, 10, 0
msg_filled:          db '2. Buffer filled with pattern', 13, 10, 0
msg_writing:         db '3. Writing buffer to disk sector 50...', 13, 10, 0
msg_write_success:   db '4. SUCCESS! Data written to disk', 13, 10, 13, 10, 0
msg_write_error:     db '4. ERROR! Failed to write to disk', 13, 10, 13, 10, 0

debug_msg:
    db 'Buffer contents (first 64 bytes): ', 0

temp_number dw 0
temp_buffer times 12 db 0       ; buffer for number-to-string conversion

test_string_123 db "123", 0
original_msg db "Original string: ", 0
converted_msg db "Converted back: ", 0
parse_error_msg db "Parse error!", 13, 10, 0

newline_str db 10, 0

; Data for calculator
first_number dw 0
second_number dw 0
operator db 0
calc_result dw 0

result_msg db "Result: ", 0
error_msg db "Calculator error! Usage: calc 5 + 3", 13, 10, 0



; ===== SECTOR PADDING =====
times (10240 - ($ - $$)) db 0
