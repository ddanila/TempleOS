; Test-only IDT setup and interrupt wait function; native HolyC owns PIC/PIT and EOI.
irq_test_code_begin:
irq_test_setup:
    mov edi,irq_test_idt
    xor eax,eax
    mov ecx,48*2
    rep stosd
    mov edi,irq_test_idt
    mov ecx,48
.fill:
    mov eax,failed
    mov [edi],ax
    shr eax,16
    mov [edi+6],ax
    mov word [edi+2],8
    mov byte [edi+5],0x8E
    add edi,8
    loop .fill
    mov esi,i386_irq_entries
    mov edi,irq_test_idt+32*8
    mov ecx,16
.irqs:
    lodsd
    mov [edi],ax
    shr eax,16
    mov [edi+6],ax
    add edi,8
    loop .irqs
    mov esi,i386_exception_entries
    mov edi,irq_test_idt
    mov ecx,17
.exceptions:
    lodsd
    mov [edi],ax
    shr eax,16
    mov [edi+6],ax
    add edi,8
    loop .exceptions
    lidt [irq_test_idtr]
    ret
irq_test_wait:
    pushad
    pushfd
    push fs
    push gs
    mov [irq_test_saved_sp],esp
    mov eax,[esp+48]
    cmp dword [esp+52],0
    jne .bad
    cmp eax,1
    jb .bad
    cmp eax,1000
    ja .bad
    mov [irq_test_target],eax
    mov dword [irq_test_ticks],0
    xor eax,eax
    mov fs,ax
    mov gs,ax
    int 0x27
    int 0x2F
    mov eax,0x11223344
    mov ebx,0x22334455
    mov ecx,0x33445566
    mov edx,0x44556677
    mov esi,0x55667788
    mov edi,0x66778899
    mov ebp,0x778899AA
    std
.wait:
    sti
    hlt
    cli
    cmp esp,[irq_test_saved_sp]
    jne .bad
    cmp eax,0x11223344
    jne .bad
    cmp ebx,0x22334455
    jne .bad
    cmp ecx,0x33445566
    jne .bad
    cmp edx,0x44556677
    jne .bad
    cmp esi,0x55667788
    jne .bad
    cmp edi,0x66778899
    jne .bad
    cmp ebp,0x778899AA
    jne .bad
    pushfd
    pop eax
    test eax,0x400
    jz .bad
    mov ax,fs
    test ax,ax
    jnz .bad
    mov ax,gs
    test ax,ax
    jnz .bad
    mov eax,[irq_test_ticks]
    cmp eax,[irq_test_target]
    jae .done
    mov eax,0x11223344
    jmp .wait
.done:
    cld
    pop gs
    pop fs
    popfd
    popad
    xor eax,eax
    xor edx,edx
    ret 8
.bad:
    cli
    cld
    mov esp,[irq_test_saved_sp]
    pop gs
    pop fs
    popfd
    popad
    mov eax,1
    xor edx,edx
    ret 8
irq_test_flags:
    pushfd
    pop eax
    xor edx,edx
    ret
; Recover only from these explicit test sites; a native handler edits saved EIP/EAX.
exception_test_run:
    pushad
    pushfd
    push fs
    push gs
    mov [irq_test_saved_sp],esp
    xor eax,eax
    mov fs,ax
    mov gs,ax
%macro fault_case 2
    mov dword [exception_test_vector],%1
    mov dword [exception_test_error],%2
%if %1 = 3
    mov dword [exception_test_ip],%%resume
%else
    mov dword [exception_test_ip],%%fault
%endif
    mov dword [exception_test_resume],%%resume
    mov eax,0x18
    mov ebx,0x22334455
    xor ecx,ecx
    xor edx,edx
    mov esi,0x55667788
    mov edi,0x66778899
    mov ebp,0x778899AA
    std
%%fault:
%if %1 = 0
    div ecx
%elif %1 = 13
    mov ds,ax
%else
    int3
%endif
%%resume:
    cmp esp,[irq_test_saved_sp]
    jne exception_test_bad
    cmp eax,0x1234ABCD
    jne exception_test_bad
    cmp ebx,0x22334455
    jne exception_test_bad
    test ecx,ecx
    jnz exception_test_bad
    test edx,edx
    jnz exception_test_bad
    cmp esi,0x55667788
    jne exception_test_bad
    cmp edi,0x66778899
    jne exception_test_bad
    cmp ebp,0x778899AA
    jne exception_test_bad
    pushfd
    pop eax
    test eax,0x400
    jz exception_test_bad
    mov ax,ds
    cmp ax,16
    jne exception_test_bad
    mov ax,es
    cmp ax,16
    jne exception_test_bad
    mov ax,fs
    test ax,ax
    jnz exception_test_bad
    mov ax,gs
    test ax,ax
    jnz exception_test_bad
%endmacro
    fault_case 0,0
    fault_case 13,0x18
    fault_case 3,0
    cld
    pop gs
    pop fs
    popfd
    popad
    xor eax,eax
    xor edx,edx
    ret
exception_test_bad:
    cli
    cld
    mov esp,[irq_test_saved_sp]
    pop gs
    pop fs
    popfd
    popad
    mov eax,1
    xor edx,edx
    ret
irq_test_code_end:
align 8
irq_test_idt: times 48 dq 0
irq_test_idtr: dw 48*8-1
    dd irq_test_idt
irq_test_saved_sp: dd 0
irq_test_target: dd 0
%include "Kernel/I386/Irq.asm"
irq_test_ticks: dd 0 ; Follows dispatch pointer: CIrqTestControl layout.
irq_test_flags_ptr: dd irq_test_flags
exception_test_run_ptr: dd exception_test_run
exception_test_dispatch_ptr: dd i386_exception_dispatch
exception_test_vector: dd 0
exception_test_error: dd 0
exception_test_ip: dd 0
exception_test_resume: dd 0
%include "Kernel/I386/Exception.asm"
