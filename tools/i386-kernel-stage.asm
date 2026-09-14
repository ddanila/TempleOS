%define BOOT_SECTORS 768
%define BOOT_VOLUME_SECTOR 2048
%include "tools/i386-bios.inc"
section stage vstart=0x10000 align=1
bits 32
    cld
    mov eax,cr0
    or eax,4 ; Software floating-point baseline: trap any accidental x87 use.
    mov cr0,eax
    mov ax,16
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    mov esp,0x90000
    xor ebp,ebp
    mov edi,early_idt
    mov ecx,256
.fill:
    mov eax,early_fault
    mov [edi],ax
    shr eax,16
    mov [edi+6],ax
    mov word [edi+2],8
    mov word [edi+4],0x8E00
    add edi,8
    loop .fill
    lidt [early_idtr]
    push dword 0
    push dword 0
    push dword 0
    push dword 0x5000
    call kernel_image
 early_fault:
    cli
    mov al,'F'
    out 0xE9,al
    hlt
    jmp early_fault
align 8
early_idt: times 256 dq 0
early_idtr: dw 256*8-1
    dd early_idt
align 8
kernel_image: incbin KERNEL_FILE
