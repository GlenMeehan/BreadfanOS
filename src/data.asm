; ===== DATA SECTION =====
; All string constants, buffers, and variables

; ===== SYSTEM MESSAGES =====
welcome_msg:
    db 'BreadfanOS Shell v2.0 - Now with 4 sectors!', 10
    db 'Type "help" for available commands.', 10, 10, 0

system_info_msg:
    db 'System: 4-sector kernel (2048 bytes)', 10
    db 'Memory: 0x7E00-0x86FF', 10, 10, 0

prompt_msg:
    db 'BreadfanOS>>', 0

goodbye_msg:
    db 'Thanks for using BreadfanOS! Shutting down...', 10, 0

safe_to_close_msg:
    db 'System halted - safe to power-off.', 10, 0

; ===== HELP AND INFO MESSAGES =====
help_msg:
    db 'Available commands:', 10
    db '  clear - Clear the screen', 10
    db '  drives    - Detect available drives', 10
    db '  exit  - Shutdown system', 10
    db '  fs    - File system status', 10
    db '  hello - Display greeting', 10
    db '  help  - Show this help', 10
    db '  info  - Show system information', 10
    db '  ls    - List files', 10
    db '  writet    - Write test to hdd', 10
    db '  readd - Read from hdd', 10
    db '  debug - Show buffer contents', 10
    db '  numtest   - Test string parsing', 10
    db '  calc  - Calculator (e.g. calc 5 + 3)', 10
    db '  write - Write a file', 10
    db '  cat   - Read file', 10
    db '  makefile  - Create new file', 10, 0

hello_msg:
    db 'Hello from BreadfanOS v2.0!', 10, 0

info_msg:
    db 'BreadfanOS Kernel Information:', 10
    db 'Version: 2.0 (4-sector)', 10
    db 'Architecture: x86 16-bit', 10
    db 'Kernel Size: 2048 bytes (4 sectors)', 10
    db 'Available Commands: 12', 10
    db 'File System: BreadfanFS initialized', 10, 0

unknown_msg:
    db 'Unknown command. Type "help" for available commands.', 10, 0

; ===== FILE SYSTEM MESSAGES =====
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

fs_create_file_msg:
    db 'New file created.', 10, 0

; ===== DISK I/O MESSAGES =====
msg_start_write:
    db 'Starting disk write test...', 13, 10, 0

msg_filling:
    db '1. Filling buffer with test pattern...', 13, 10, 0

msg_filled:
    db '2. Buffer filled with pattern', 13, 10, 0

msg_writing:
    db '3. Writing buffer to disk sector 50...', 13, 10, 0

msg_write_success:
    db '4. SUCCESS! Data written to disk', 13, 10, 13, 10, 0

msg_write_error:
    db '4. ERROR! Failed to write to disk', 13, 10, 13, 10, 0

debug_msg:
    db 'Buffer contents (first 64 bytes): ', 0

; ===== DRIVE DETECTION MESSAGES =====
drives_header:
    db 'Detecting available drives...', 10, 0

floppy_found:
    db 'Drive 0x00: Floppy disk detected', 10, 0

hdd_found:
    db 'Drive 0x80: Hard disk detected', 10, 0

; ===== CALCULATOR MESSAGES =====
result_msg:
    db "Result: ", 0

error_msg:
    db "Calculator error! Usage: calc 5 + 3", 13, 10, 0

original_msg:
    db "Original string: ", 0

converted_msg:
    db "Converted back: ", 0

parse_error_msg:
    db "Parse error!", 13, 10, 0

; ===== COMMAND STRINGS =====
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
cmd_calc_test:      db 'numtest', 0
calc_cmd:           db 'calc', 0
cmd_debug:          db 'debug', 0
cmd_write:          db 'write', 0
cmd_cat:            db 'cat', 0

; ===== BUFFERS AND VARIABLES =====
command_buffer:     times 64 db 0
first_word_buffer:  times 32 db 0
temp_buffer:        times 12 db 0
temp_char:          db 0, 0

newline:            db 10, 0
newline_str:        db 10, 0

content_buffer:     times 512 db 0   ; Buffer for file content (1 sector)

; ===== FILE SYSTEM DATA =====
fs_directory:       times (FS_MAX_FILES * FS_ENTRY_SIZE) db 0

test_file1:         db 'readme.txt', 0
test_file2:         db 'config.sys', 0

test_string_123:    db "123", 0

fs_file_detail:     db ' - ', 0
bytes_msg:          db ' bytes, sector ', 0
sector_msg:         db '', 0
fs_no_space_msg:    db 'Error: No space in directory (max 8 files)', 10, 0
fs_file_not_found:  db 'Error: File not found', 10, 0
fs_write_success:   db 'File written successfully', 10, 0
fs_read_success:    db 'File contents:', 10, 0


; ===== CALCULATOR VARIABLES =====
first_number:       dw 0
second_number:      dw 0
operator:           db 0
calc_result:        dw 0

; Write command messages
write_usage_msg:        db 'Usage: write <filename> <content>', 10, 0
write_no_content_msg:   db 'Error: No content specified', 10, 0
fs_write_error_msg:     db 'Error: Failed to write file', 10, 0

; Cat command messages
cat_usage_msg:          db 'Usage: cat <filename>', 10, 0
cat_empty_msg:          db '(empty file)', 10, 0
cat_error_msg:          db 'Error: Failed to read file', 10, 0
