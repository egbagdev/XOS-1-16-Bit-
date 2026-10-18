; boot.asm - 16-bit Bootloader (Extended Size)
[org 0x7C00]
[bits 16]

    mov [BOOT_DRIVE], dl
    mov ah, 0x02
    mov al, 15          ; [수정됨] 커널을 15섹터(7680바이트)까지 넉넉하게 읽어옴!
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov bx, 0x1000
    int 0x13

    jmp 0x1000

BOOT_DRIVE db 0

times 510-($-$$) db 0
dw 0xAA55