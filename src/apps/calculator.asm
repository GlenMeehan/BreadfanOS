; ===== CALCULATOR APPLICATION =====
; Simple calculator handling expressions like: calc 5 + 3

; Main calculator function
; Input: command_buffer contains "calc <num1> <op> <num2>"
calculator:
    pusha

    ; Skip past "calc " (5 characters)
    mov si, command_buffer
    add si, 5

    ; Parse first number
    call skip_whitespace
    call str_to_int
    jc .calc_error
    mov [first_number], ax

    ; Parse operator
    call skip_whitespace
    mov al, [si]
    mov [operator], al
    inc si

    ; Validate operator
    cmp al, '+'
    je .valid_op
    cmp al, '-'
    je .valid_op
    cmp al, '*'
    je .valid_op
    cmp al, '/'
    je .valid_op
    jmp .calc_error

.valid_op:
    ; Parse second number
    call skip_whitespace
    call str_to_int
    jc .calc_error
    mov [second_number], ax

    ; Perform calculation
    call do_calculation
    jc .calc_error

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

; Perform the actual calculation
; Uses first_number, second_number, and operator
; Output: AX = result, CF = 1 on error
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
    stc
    popa
    ret

.do_add:
    add ax, bx
    jmp .calc_done

.do_sub:
    sub ax, bx
    jmp .calc_done

.do_mul:
    mul bx
    jmp .calc_done

.do_div:
    test bx, bx         ; Check for division by zero
    jz .div_error
    xor dx, dx
    div bx
    jmp .calc_done

.div_error:
    stc
    popa
    ret

.calc_done:
    mov [calc_result], ax
    clc
    popa
    mov ax, [calc_result]
    ret

; Test number parsing functions
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

    ; Show the integer value
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
