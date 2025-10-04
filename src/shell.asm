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
