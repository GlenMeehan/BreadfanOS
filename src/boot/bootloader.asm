[org 0x7C00]
[bits 16]
    mov ah, 0x02     ; Read sectors
    mov al, 20       ; 20 sector
    mov bx, 0x7E00   ; Load to 0x7E00
    mov ch, 0        ; Cylinder 0
    mov cl, 2        ; Sector 2
    mov dh, 0        ; Head 0
    mov dl, 0x80     ; Drive number (0x80 = first hard drive)
    int 0x13         ; Read from disk
    jmp 0x7E00       ; Now jump to loaded kernel

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55
