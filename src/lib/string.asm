; ===== STRING UTILITIES =====
; String manipulation and comparison functions

; Compare two null-terminated strings
; Input: SI = pointer to first string
;        DI = pointer to second string
; Output: AX = 0 if equal, 1 if not equal
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

; Universal command checker - eliminates repetitive strcmp calls
; Input: SI = command_buffer, DI = command_string
; Output: Zero flag set if match, clear if no match
check_command:
    push ax
    call strcmp
    test ax, ax         ; Set zero flag if AX=0 (match)
    pop ax
    ret

; Extract first word from command_buffer into first_word_buffer
; Input: SI = source buffer (command_buffer)
;        DI = destination buffer (first_word_buffer)
; Output: First word copied to DI, null-terminated
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

; Skip whitespace characters (space, tab)
; Input: SI = pointer to string
; Output: SI = pointer to first non-whitespace character
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
