; ===== DISPLAY DRIVER =====
; Screen output, cursor control, and color management
; Uses BIOS int 0x10 functions

; Print colored string
; Input: SI = pointer to null-terminated string
;        BL = color attribute
; Output: String printed to screen in specified color
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

; Handle newline with automatic scrolling
handle_newline_colored:
    call get_cursor

    ; Check if we're on bottom row (row 24)
    cmp dh, 24
    jl .normal_newline

    ; We're at bottom - scroll instead of moving to next line
    call scroll_up
    jmp print_colored_loop

.normal_newline:
    ; Normal newline handling
    inc dh
    mov dl, 0
    call set_cursor
    jmp print_colored_loop

; Scroll screen up by one line
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

; Clear the screen
; Output: Screen cleared, cursor at top-left
clear_screen:
    mov ah, 0x06        ; Scroll up function
    mov al, 0           ; Clear entire screen
    mov bh, 0x07        ; White on black
    mov cx, 0x0000      ; Top-left (0,0)
    mov dx, 0x184F      ; Bottom-right (24,79)
    int 0x10
    mov dh, 0
    mov dl, 0
    call set_cursor
    ret

; Set cursor position
; Input: DH = row, DL = column
set_cursor:
    push ax
    push bx
    mov ah, 0x02
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret

; Get cursor position
; Output: DH = row, DL = column
get_cursor:
    push ax
    push bx
    mov ah, 0x03
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret

; Advance cursor by one position
; Handles wrap-around to next line
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

; Print a single character (used by debug functions)
; Input: AL = character to print
debug_print_char:
    push ax
    push bx
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret
