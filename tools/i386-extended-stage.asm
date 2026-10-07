; Extended CHS loader prototype: BIOS bounce buffer, protected-mode high copy.
%define BOOT_SECTORS 8
%define BOOT_SECTORS_LIMIT 960
%define BOOT_VOLUME_SECTOR 2048
%include "tools/i386-bios.inc"
section stage vstart=0x10000 align=1
bits 32
stage_entry: db 0xE9
    dd start32-($+4)
    times 16-($-$$) db 0
image_magic: dd 0x42323345
image_version: dd 1
payload_bytes: dd kernel_end-kernel_image
payload_base: dd 0x100000
payload_hash: dd PAYLOAD_FNV
boot_drive: db 0
stage_spt: dw 0
stage_heads: dw 0
next_sector: dw 9
remaining: dd 0
destination: dd 0
align 8
extended_gdt:
    dq 0
    dq 0x00cf9a000000ffff
    dq 0x00cf92000000ffff
    dq 0x00009a010000ffff ;16-bit code base 0x10000.
    dq 0x000092000000ffff ;16-bit data base zero.
extended_gdtr:
    dw $-extended_gdt-1
    dd extended_gdt
start32: mov ax,16
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,0x90000
    cld
    mov edi,early_idt
    mov ecx,256
.fill_idt:
    mov eax,early_fault
    mov [edi],ax
    shr eax,16
    mov [edi+6],ax
    mov word [edi+2],8
    mov word [edi+4],0x8E00
    add edi,8
    loop .fill_idt
    lidt [early_idtr]
%ifdef EARLY_IDT_TEST
    int3
%endif
    cmp dword [image_magic],0x42323345
    jne fail32
    cmp dword [image_version],1
    jne fail32
    cmp dword [payload_base],0x100000
    jne fail32
    mov eax,[payload_bytes]
    cmp eax,8
    jb fail32
    cmp eax,2039*512
    ja fail32
    mov edx,[0x500C]
    shl edx,10
    cmp eax,edx
    ja fail32
    add eax,511
    shr eax,9
    mov [remaining],eax
    mov dword [destination],0x100000
    mov al,[0x5028]
    mov [boot_drive],al
%ifdef A20_KBC_TEST
    ;Fixture only: turn off both gates to force the verified controller path.
    call a20_kbc_empty
    jc fail32
    mov al,0xD1
    out 0x64,al
    call a20_kbc_empty
    jc fail32
    mov al,0xDD
    out 0x60,al
    call a20_kbc_empty
    jc fail32
    in al,0x92
    and al,0xFC
    out 0x92,al
    call a20_test
    jz fail32
%endif
    call a20_test
    jz a20_ready
    call a20_kbc_empty
    jc a20_fast
    mov al,0xD1
    out 0x64,al
    call a20_kbc_empty
    jc a20_fast
    mov al,0xDF
    out 0x60,al
    call a20_kbc_empty
    jc a20_fast
    call a20_test
    jz a20_ready
a20_fast:
%ifdef A20_KBC_TEST
    jmp fail32
%endif
    in al,0x92
    cmp al,0xFF
    je fail32
    and al,0xFE
    or al,2
    out 0x92,al
    call a20_test
    jnz fail32
a20_ready:
    lgdt [extended_gdtr]
    jmp word 24:pm16-$$
bits 16
pm16: mov ax,32
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov eax,cr0
    and eax,0xFFFFFFFE
    mov cr0,eax
    jmp 0x1000:real16-$$
real16:
    xor ax,ax
    mov ss,ax
    mov sp,0x9000
    mov es,ax
    mov ax,0x1000
    mov ds,ax
    lidt [real_idtr-$$]
    sti
    cmp word [stage_spt-$$],0
    jne read_sector
    mov dl,[boot_drive-$$]
    mov ah,8
    int 0x13
    jc fail16_stage
    and cx,63
    mov [stage_spt-$$],cx
    xor ax,ax
    mov al,dh
    inc ax
    mov [stage_heads-$$],ax
read_sector:
    mov ax,[next_sector-$$]
    xor dx,dx
    div word [stage_spt-$$]
    mov cl,dl
    inc cl
    xor dx,dx
    div word [stage_heads-$$]
    mov dh,dl
    mov ch,al
    shl ah,6
    or cl,ah
    mov bx,0x6000
    mov dl,[boot_drive-$$]
    mov ax,0x0201
    int 0x13
    jc fail16_stage
    cli
    lgdt [extended_gdtr-$$]
    mov eax,cr0
    or eax,1
    mov cr0,eax
    jmp dword 8:copy32
fail16_stage:
    mov al,'B'
    out 0xE9,al
    cli
    hlt
    jmp fail16_stage
bits 32
copy32: mov ax,16
    mov ds,ax
    mov es,ax
    mov ss,ax
    lidt [early_idtr]
    mov esp,0x90000
    cld
    mov esi,0x6000
    mov edi,[destination]
    mov ecx,128
    rep movsd
    mov [destination],edi
    inc word [next_sector]
    dec dword [remaining]
    jnz switch16
    mov esi,[payload_base]
    mov ecx,[payload_bytes]
    mov eax,2166136261
hash_loop:
    movzx ebx,byte [esi]
    xor eax,ebx
    imul eax,eax,16777619
    inc esi
    dec ecx
    jnz hash_loop
    cmp eax,[payload_hash]
    jne fail32
    mov esi,[payload_base]
    cmp byte [esi],0xE9
    jne fail32
    cmp word [esi+5],0
    jne fail32
    cmp byte [esi+7],0
    jne fail32
    mov eax,[esi+1]
    add eax,5
    cmp eax,8
    jb fail32
    cmp eax,[payload_bytes]
    jae fail32
    ;Separate versioned image handoff; keep the legacy memory/disk ABIs.
    mov dword [0x5030],0x42323345
    mov dword [0x5034],1
    mov eax,[payload_base]
    mov [0x5038],eax
    mov edx,[payload_bytes]
    mov [0x503C],edx
    mov edx,cr0
    or edx,4
    mov cr0,edx
    xor ebp,ebp
    push dword 0
    push dword 0
    push dword 0
    push dword 0x5000
    call eax
fail32:
    mov al,'B'
    out 0xE9,al
    cli
    hlt
    jmp fail32
switch16:
    jmp word 24:pm16-$$
a20_test:
    mov al,[0x5100]
    mov bl,[0x105100]
    mov byte [0x5100],0x12
    mov byte [0x105100],0xA7
    cmp byte [0x5100],0x12
    jne a20_restore
    cmp byte [0x105100],0xA7
a20_restore:
    mov [0x105100],bl
    mov [0x5100],al
    ret
a20_kbc_empty:
    mov ecx,100000
a20_kbc_poll:
    in al,0x80
    in al,0x64
    cmp al,0xFF
    je a20_kbc_next
    test al,1
    jz a20_kbc_input
    in al,0x60
    jmp a20_kbc_next
a20_kbc_input:
    test al,2
    jz a20_kbc_ok
a20_kbc_next:
    loop a20_kbc_poll
    stc
    ret
a20_kbc_ok:
    clc
    ret
early_fault:
    cli
    mov al,'F'
    out 0xE9,al
    hlt
    jmp early_fault
stage_code_end: db 0
align 8
early_idt: times 256 dq 0
early_idtr: dw 256*8-1
    dd early_idt
real_idtr: dw 0x3FF
    dd 0
times 4096-($-$$) db 0
kernel_image: incbin KERNEL_FILE
kernel_end:
