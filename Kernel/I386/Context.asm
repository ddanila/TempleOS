; U0 switch(CI386Context *old,CI386Context *next), eight-byte argument slots.
; Flat ring 0, IF clear; caller owns contexts/stacks and scheduling policy.
; Same address space. No FPU/debug-register state or CPU/task descriptor update.
bits 32
i386_context_code_begin:
i386_context_switch:
    pushfd
    pushad
    push ds
    push es
    push fs
    push gs
    mov eax,[esp+56]
    mov edx,[esp+64]
    mov [eax],esp
    mov esp,[edx]
    pop gs
    pop fs
    pop es
    pop ds
    popad
    popfd
    ret 16
i386_context_code_end:
