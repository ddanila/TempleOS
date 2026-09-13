; BIOS CHS test runner for compiler-produced i386 code. Not the ported kernel.
bits 16
org 0x7c00
    cli
    xor ax,ax
    mov ds,ax
    mov ss,ax
    mov sp,0x7c00
    sti
    mov [drive],dl
    mov ah,8
    int 0x13
    jc fail16
    and cx,63
    mov [spt],cx
    xor ax,ax
    mov al,dh
    inc ax
    mov [heads],ax
    mov ax,0x1000
    mov es,ax
    mov word [sector],1
    mov si,64
.load:
    mov ax,[sector]
    xor dx,dx
    div word [spt]
    mov cl,dl
    inc cl
    xor dx,dx
    div word [heads]
    mov dh,dl
    mov ch,al
    shl ah,6
    or cl,ah
    xor bx,bx
    mov dl,[drive]
    mov ax,0x0201
    push si
    int 0x13
    pop si
    jc fail16
    mov ax,es
    add ax,32
    mov es,ax
    inc word [sector]
    dec si
    jnz .load
    mov ax,0x12
    int 0x10
    cli
    lgdt [gdt_ptr]
    mov eax,cr0
    or eax,1
    mov cr0,eax
    jmp dword 8:0x10000
fail16:
    mov al,'B'
    out 0xe9,al
    cli
    hlt
    jmp fail16
drive: db 0
spt: dw 0
heads: dw 0
sector: dw 0
align 8
gdt:
    dq 0
    dq 0x00cf9a000000ffff
    dq 0x00cf92000000ffff
gdt_ptr:
    dw $-gdt-1
    dd gdt
times 510-($-$$) db 0
dw 0xaa55

