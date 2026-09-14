; Shared BIOS CHS loader and legacy memory handoff for native kernel/test images.
%ifndef BOOT_SECTORS
%define BOOT_SECTORS 128
%endif
%if BOOT_SECTORS < 1 || BOOT_SECTORS > 320
%error Test stage must fit below physical 0x38000
%endif
bits 16
org 0x7c00
    cli
    xor ax,ax
    mov ds,ax
    mov ss,ax
    mov sp,0x7c00
    sti
    mov [drive],dl
    ; Fixed-width handoff at 0x5000; all bytes below the stage remain reserved.
    mov dword [0x5000],0x4D323349
    mov dword [0x5004],1
    mov dword [0x500C],0
    mov dword [0x5014],0x10000
    mov dword [0x5018],0x10000+BOOT_SECTORS*512
    mov dword [0x501C],1
    push ds
    int 0x12
    pop ds
    cmp ax,576 ; Native entry stacks currently end at 0x90000.
    jb fail16
    cmp ax,640
    ja fail16
    movzx eax,ax
    mov [0x5008],eax
    movzx eax,word [0x40E]
    shl eax,4
    mov [0x5010],eax
    test eax,eax
    jz .ebda_ok
    cmp eax,0x90000
    jb fail16
    cmp eax,0xA0000
    ja fail16
.ebda_ok:
    mov ah,0x88
    stc
    push ds
    int 0x15
    pop ds
%ifdef BOOT_EXTENDED_FAIL
    stc ; Exercise an unsupported legacy query on an emulator BIOS.
%endif
    jc .no_extended
    movzx eax,ax
    mov [0x500C],eax
    or dword [0x501C],2
.no_extended:
    mov dl,[drive]
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
    mov si,BOOT_SECTORS
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
