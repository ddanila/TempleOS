; 386 ring-0 hardware IRQ entry. Fixed-address bootstrap assembly for now.
; Install these at IDT vectors 0x20..0x2F as 32-bit interrupt gates.
; Set i386_irq_dispatch before unmasking IRQs. It is U0 handler(CI386IrqFrame *).
; The callback keeps IF clear and owns PIC spurious handling and EOI.
bits 32
i386_irq_stubs_begin:
%assign irq 0
%rep 16
 i386_irq_%+irq:
    push dword irq
    jmp i386_irq_common
%assign irq irq+1
%endrep
i386_irq_common:
    pushad
    push ds
    push es
    push fs
    push gs
    cld
    mov ax,16
    mov ds,ax
    mov es,ax
    ; FS/GS retain the interrupted task/CPU selectors; all selectors are restored.
    cmp dword [i386_irq_dispatch],0
    je .unhandled
    mov eax,esp
    push dword 0
    push eax
    call [i386_irq_dispatch]
    pop gs
    pop fs
    pop es
    pop ds
    popad
    add esp,4
    iretd
.unhandled:
    cli
    hlt
    jmp .unhandled
i386_irq_stubs_end:
align 4
i386_irq_entries:
%assign irq 0
%rep 16
    dd i386_irq_%+irq
%assign irq irq+1
%endrep
i386_irq_dispatch: dd 0
