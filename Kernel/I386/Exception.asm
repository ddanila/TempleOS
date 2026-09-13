; Same-ring 386 exception entry; requires an intact flat ring-0 stack.
; Fixed-address bootstrap, CS=8, DS=ES=16. No PIC acknowledgement.
; Callback: U0 handler(CI386ExceptionFrame *), with IF/DF clear, no yielding.
; Do not use software INT for vectors that normally push CPU error codes.
bits 32
i386_exception_stubs_begin:
%assign vector 0
%rep 17
i386_exception_%+vector:
%if vector != 8 && (vector < 10 || vector > 14)
    push dword 0
%endif
    push dword vector
    jmp i386_exception_common
%assign vector vector+1
%endrep
i386_exception_common:
    pushad
    push ds
    push es
    push fs
    push gs
    cld
    mov ax,16
    mov ds,ax
    mov es,ax
    cmp dword [i386_exception_dispatch],0
    je .unhandled
    mov eax,esp
    push dword 0
    push eax
    call [i386_exception_dispatch]
    pop gs
    pop fs
    pop es
    pop ds
    popad
    add esp,8
    iretd
.unhandled:
    cli
    hlt
    jmp .unhandled
i386_exception_stubs_end:
align 4
i386_exception_entries:
%assign vector 0
%rep 17
    dd i386_exception_%+vector
%assign vector vector+1
%endrep
i386_exception_dispatch: dd 0
