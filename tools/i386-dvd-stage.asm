; 386 El Torito stage1. Patches: LBA at 20, DVD block count at 24,
; 512-byte leading-block shift at 26. Handoff matches TempleOS BootDVD:
; EAX=(shift<<16)|BOOT_SRC_DVD, EBX=DVD LBA, CS:IP=07C0:0000.
bits 16
org 0
    jmp start
    times 16-($-$$) db 0
    db 'I3CD'
source_lba: dd 0
block_count: dw 0
block_shift: dw 0
start:
    cld
    cli
    mov ax,0x9660
    mov es,ax
    mov ss,ax
    mov sp,0xA00
    ; BIOS may enter either 0000:7C00 or 07C0:0000.
    xor ax,ax
    mov ds,ax
    mov si,0x7C00
    xor di,di
    mov cx,2048
    rep movsb
    jmp 0x9660:relocated
relocated:
    mov ax,cs
    mov ds,ax
    mov [drive],dl
    sti
    cmp word [block_count],0
    je invalid
    cmp word [block_count],285
    ja invalid
    cmp word [block_shift],3
    ja invalid
    mov eax,[source_lba]
    mov [read_lba],eax
    mov cx,[block_count]
read_next:
    push cx
    mov si,dap
    mov dl,[drive]
    mov ah,0x42
    int 0x13
    jc read_error
    add word [buffer_segment],128
    add dword [read_lba],1
    adc dword [read_lba+4],0
    pop cx
    loop read_next
    ; Shift only loaded bytes, using 512-byte segment-bounded copies.
    mov bx,[block_shift]
    test bx,bx
    jz handoff
    mov dx,[block_count]
    shl dx,2
    sub dx,bx
    shl bx,5
    mov ax,0x07C0
    mov es,ax
    add ax,bx
    mov ds,ax
copy_next:
    xor si,si
    xor di,di
    mov cx,128
    rep movsd
    mov ax,ds
    add ax,32
    mov ds,ax
    mov ax,es
    add ax,32
    mov es,ax
    dec dx
    jnz copy_next
    mov ax,cs
    mov ds,ax
handoff:
    mov ebx,[source_lba]
    movzx eax,word [block_shift]
    shl eax,16
    mov ax,4
    mov dl,[drive]
    jmp 0x07C0:0
invalid:
    mov al,'V'
    jmp failure
read_error:
    mov al,'R'
failure:
    out 0xE9,al
    mov ah,0x0E
    mov bx,7
    int 0x10
    cli
halt:
    hlt
    jmp halt
drive: db 0
align 4
dap: db 16,0
    dw 1,0
buffer_segment: dw 0x07C0
read_lba: dq 0
    times 2048-($-$$) db 0
