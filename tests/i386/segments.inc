; Test-only temporary GDT: retain flat code/data and add FS/GS records in low RAM.
segment_test_code_begin:
segment_test_run:
    push ebp
    mov ebp,esp
    push ebx
    push esi
    push edi
    push fs
    push gs
    sub esp,8
    sgdt [esp]
    lgdt [segment_test_gdtr]
    mov ax,0x18
    mov fs,ax
    mov ax,0x20
    mov gs,ax
    call [ebp+8]
    lgdt [esp]
    add esp,8
    pop gs
    pop fs
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret 8
segment_test_code_end:
align 8
segment_test_gdt:
    dq 0,0x00cf9a000000ffff,0x00cf92000000ffff
    dw 0xFFFF,0
    db 5,0x92,0x40,0
    dw 0xFFFF,0x100
    db 5,0x92,0x40,0
segment_test_gdtr:
    dw 5*8-1
    dd segment_test_gdt
