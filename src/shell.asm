; ===== SHELL MODULE =====
; Command-line interface and command processing

; Display welcome message
show_welcome:
    mov si, welcome_msg
    mov bl, LIGHT_CYAN
    call print_colored
    ret

; Display system information
show_system_info:
    mov si, system_info_msg
    mov bl, LIGHT_CYAN
    call print_colored
    ret

; Display command prompt
show_prompt:
    mov si, prompt_msg
    mov bl, YELLOW
    call print_colored
    ret

; Read command from user
; Output: command stored in command_buffer
read_command:
    mov di, command_buffer
    mov cx, 0

read_loop:
    call wait_for_key
    cmp al, 13              ; Enter key
    je read_done
    cmp al, 8               ; Backspace
    je handle_backspace
    cmp al, 32              ; Below space (control chars)
    jl read_loop
    cmp al, 126             ; Above tilde
    jg read_loop
    cmp cx, 63              ; Buffer full?
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

; Wait for keyboard input
; Output: AL = ASCII character, AH = scan code
wait_for_key:
    mov ah, 0x00
    int 0x16
    ret

; Process command from command_buffer
process_command:
    mov si, command_buffer

    ; Check for help command
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

    ; Check for calculator (multi-word command)
    call extract_first_word
    mov si, first_word_buffer
    mov di, calc_cmd
    call check_command
    jz calculator

    mov di, cmd_write
    call check_command
    jz cmd_write_handler

    mov di, cmd_cat
    call check_command
    jz cmd_cat_handler

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



; Usage: write <filename> <content>
cmd_write_handler:
    pusha

    ; Extract filename (skip "write ")
    mov si, command_buffer
    add si, 6  ; Skip "write "

    ; Copy filename to temp_buffer
    mov di, temp_buffer
    xor cx, cx

.copy_filename:
    lodsb
    cmp al, 0
    je .no_filename
    cmp al, ' '
    je .filename_done
    stosb
    inc cx
    cmp cx, 12
    jl .copy_filename

.filename_done:
    mov byte [di], 0  ; Null terminate filename

    ; Skip spaces to find content
.skip_space:
    lodsb
    cmp al, 0
    je .no_content
    cmp al, ' '
    je .skip_space

    ; SI now points to start of content
    ; Copy content to content_buffer
    dec si  ; Back up one (we read one too far)
    mov di, content_buffer
    xor cx, cx

.copy_content:
    lodsb
    cmp al, 0
    je .content_done
    cmp al, 13  ; Carriage return
    je .content_done
    stosb
    inc cx
    cmp cx, 511  ; Max content size
    jl .copy_content

.content_done:
    mov byte [di], 0  ; Null terminate content

    ; Now call fs_write_file
    ; Input: SI = filename, DI = content buffer, CX = content length
    mov si, temp_buffer
    mov di, content_buffer
    ; CX already has length
    call fs_write_file

    jc .write_success

    ; Write failed
    mov si, fs_write_error_msg
    mov bl, LIGHT_RED
    call print_colored
    jmp .done

.write_success:
    mov si, fs_write_success
    mov bl, LIGHT_GREEN
    call print_colored
    jmp .done

.no_filename:
    mov si, write_usage_msg
    mov bl, YELLOW
    call print_colored
    jmp .done

.no_content:
    mov si, write_no_content_msg
    mov bl, YELLOW
    call print_colored

.done:
    popa
    ret

; Cat command handler
; Usage: cat <filename>
cmd_cat_handler:
    pusha

    ; Extract filename (skip "cat ")
    mov si, command_buffer
    add si, 4  ; Skip "cat "

    ; Copy filename to temp_buffer
    mov di, temp_buffer
    xor cx, cx

.copy_filename:
    lodsb
    cmp al, 0
    je .filename_done
    cmp al, ' '
    je .filename_done
    cmp al, 13
    je .filename_done
    stosb
    inc cx
    cmp cx, 12
    jl .copy_filename

.filename_done:
    mov byte [di], 0  ; Null terminate

    ; Check if filename is empty
    cmp byte [temp_buffer], 0
    je .no_filename

    ; Find the file
    mov si, temp_buffer
    call fs_find_file
    jnc .file_not_found

    ; DI points to directory entry
    ; Check if file has content
    mov cx, [di + 12]  ; File size
    test cx, cx
    jz .empty_file

    ; Read the file
    mov si, temp_buffer
    call fs_read_file
    jnc .read_error

    ; Print the content
    mov si, content_buffer
    mov bl, WHITE
    call print_colored
    mov si, newline_str
    call print_colored
    jmp .done

.no_filename:
    mov si, cat_usage_msg
    mov bl, YELLOW
    call print_colored
    jmp .done

.file_not_found:
    mov si, fs_file_not_found
    mov bl, LIGHT_RED
    call print_colored
    jmp .done

.empty_file:
    mov si, cat_empty_msg
    mov bl, LIGHT_GRAY
    call print_colored
    jmp .done

.read_error:
    mov si, cat_error_msg
    mov bl, LIGHT_RED
    call print_colored

.done:
    popa
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
