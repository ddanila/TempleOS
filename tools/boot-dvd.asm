; BIOS El Torito loader for the existing TempleOS kernel.
; Same handoff as Adam/Opt/Boot/BootDVD.HC: EAX=DVD, EBX=kernel LBA.
bits 16
org 0
    cld
    cli
    mov ax, 0x9660
    mov es, ax
    mov ss, ax
    mov sp, 0x2800
    xor ax, ax
    mov ds, ax
    mov si, 0x7c00
    xor di, di
    mov cx, 2048
    rep movsb
    jmp 0x9660:relocated
relocated:
    mov ax, cs
    mov ds, ax
    sti
    mov [drive], dl
    mov cx, KERNEL_BLOCKS
.read:
    push cx
    mov si, dap
    mov dl, [drive]
    mov ah, 0x42
    int 0x13
    jc failed
    add word [buffer_segment], 128
    inc dword [lba]
    pop cx
    loop .read
    mov ebx, KERNEL_LBA
    mov eax, 4
    jmp 0x07c0:0
failed:
    mov ax, 0x0e45
    mov bx, 7
    int 0x10
    cli
    hlt
    jmp failed
drive: db 0
align 4
dap: db 16, 0
    dw 1, 0
buffer_segment: dw 0x07c0
lba: dq KERNEL_LBA
times 2048-($-$$) db 0
