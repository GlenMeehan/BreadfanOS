[org 0x7E00]
[bits 16]

jmp kernel_start    ; First instruction - jump over all the functions

; ===== BREADFANOS KERNEL - MODULAR VERSION =====
; Main entry point and module includes

; ===== INCLUDES =====
%include "constants.asm"
%include "lib/string.asm"
%include "lib/math.asm"
%include "drivers/display.asm"
%include "drivers/disk.asm"
%include "fs/breadfanfs.asm"
%include "apps/calculator.asm"
%include "shell.asm"
%include "data.asm"

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

; ===== SECTOR PADDING =====
times (10240 - ($ - $$)) db 0
