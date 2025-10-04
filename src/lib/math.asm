; ===== MATH UTILITIES =====
; Number parsing and conversion functions

; Convert string to integer
; Input:  SI -> NUL-terminated (or space-terminated) string
; Output: AX = parsed value (0..65535)
;         CF = 0 on success (at least one digit parsed), CF = 1 on error
; Side effects: SI is advanced to first non-digit (space/operator/etc.)
; Preserves: BX, CX, DX
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
    jb .done_if_any   ; not a digit -> done
    cmp bl, '9'
    ja .done_if_any   ; not a digit -> done
    ; it's a digit
    sub bl, '0'       ; numeric value 0..9
    ; multiply AX by 10
    mov dx, ax
    shl ax, 3         ; AX = AX * 8
    add ax, dx        ; AX = AX*9
    add ax, dx        ; AX = AX*10
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

; Convert integer to string
; Input:  AX = value, DI -> buffer (must have enough space)
; Output: buffer filled with ASCII digits and terminated with 0
; Preserves: BX, CX, DX
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
    ; Push digits on stack then pop to buffer
.conv_loop:
    xor dx, dx
    div bx          ; AX = AX/10, DX = remainder (0..9)
    push dx         ; push remainder
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
