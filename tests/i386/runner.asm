%ifdef TASK_TEST
%define INTERRUPT_SETUP
%endif
%ifdef IRQ_TEST
%define INTERRUPT_SETUP
%endif
%include "tests/i386/boot.inc"

; This section is loaded at 0x10000, hence labels need that virtual origin.
section stage vstart=0x10000 align=1
bits 32
    cld
%ifdef SOFT_F64_TEST
    mov eax,cr0
    or eax,4 ; CR0.EM: x87 instructions must fault even on the QEMU 486.
    mov cr0,eax
%endif
    mov ax,16
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
%ifdef INTERRUPT_SETUP
    mov esp,0x90000
    call irq_test_setup
%else
    lidt [idt_ptr]
%endif
    mov esp,0x90000
    mov esi,cases
    xor ebp,ebp
case_next:
    mov ecx,[esi]
    test ecx,ecx
    jz passed
%ifdef FUNCTIONS
    lea edi,[esi+ecx+28]
%else
    lea edi,[esi+ecx+12]
%endif
    push edi
    push esi
%ifdef FUNCTIONS
    mov ebx,0x12345678
    mov ebp,esp
    mov [call_stack],esp
%ifdef IRQ_TEST
    push dword 0
    push dword irq_test_wait
    push dword 0
    push dword i386_irq_dispatch
%elifdef EXCEPT_CONTEXT_TEST
    push dword 0
    push dword 0
    push dword 0
    push dword except_context_control
%elifdef TASK_TEST
%ifdef EXCEPT_TASK_TEST
    ;This runtime links its own task/exception entries and initializes its GDT.
    push dword 0
    push dword 0
    push dword 0
    push dword 0
%else
    push dword 0
    push dword i386_context_switch
    push dword 0
    push dword task_test_control
%endif
%else
    push dword [esi+24]
    push dword [esi+20]
    push dword [esi+16]
    push dword [esi+12]
%endif
%ifdef FIXED_IMAGE_BASE
    push esi
    push edi
    mov ecx,[esi]
    lea esi,[esi+28]
    mov edi,FIXED_IMAGE_BASE
    cld
    rep movsb
    pop edi
    pop esi
    mov eax,FIXED_IMAGE_BASE
%else
    lea eax,[esi+28]
%endif
    call eax
    cmp esp,ebp
    jne failed
    cmp ebx,0x12345678
    jne failed
    cmp esi,[esp]
    jne failed
    cmp edi,[esp+4]
    jne failed
%else
    lea eax,[esi+12]
    call eax
%endif
    pop esi
    pop edi
    cmp eax,[esi+4]
    jne failed
    cmp edx,[esi+8]
    jne failed
advance:
    inc dword [case_index]
    mov esi,edi
    jmp case_next
fault_handler:
    inc dword [fault_count]
    mov esp,[call_stack]
    pop esi
    pop edi
    cmp dword [esi+4],0xCAFEBABE
    jne failed
    cmp dword [esi+8],0xDEADBEEF
    jne failed
    jmp advance
passed:
    cmp dword [fault_count],EXPECTED_FAULTS
    jne failed
    mov esi,passmsg
    call puts
%ifdef VGA_TEST
    jmp stop
%endif
    mov eax,0x10
    out 0xf4,eax
    jmp stop
failed:
    mov [test_result],eax
    mov esi,failmsg
    call puts
    mov ebx,hex_digits
    mov eax,[case_index]
    shr al,4
    and al,15
    xlatb
    out 0xe9,al
    mov eax,[case_index]
    and al,15
    xlatb
    out 0xe9,al
    mov al,':'
    out 0xe9,al
    mov eax,[test_result]
    shr al,4
    and al,15
    xlatb
    out 0xe9,al
    mov eax,[test_result]
    and al,15
    xlatb
    out 0xe9,al
    mov al,10
    out 0xe9,al
    mov eax,0x11
    out 0xf4,eax
stop:
    cli
    hlt
    jmp stop
puts:
    lodsb
    test al,al
    jz .done
    out 0xe9,al
    jmp puts
.done:
    ret
%ifdef VGA_TEST
passmsg: db 'DONE i386 VGA',10,0
failmsg: db 'FAIL i386 VGA',10,0
%elifdef FUNCTIONS
passmsg: db 'PASS i386 functions',10,0
failmsg: db 'FAIL i386 functions',10,0
%else
passmsg: db 'PASS i386 expressions',10,0
failmsg: db 'FAIL i386 expressions',10,0
%endif
align 8
idt:
    dw (fault_handler-$$+0x10000)&0xFFFF,8
    db 0,0x8E
    dw (fault_handler-$$+0x10000)>>16
idt_ptr:
    dw 7
    dd idt
fault_count: dd 0
call_stack: dd 0
case_index: dd 0
hex_digits: db "0123456789ABCDEF"
test_result: dd 0
%ifdef INTERRUPT_SETUP
%include "tests/i386/irq.inc"
%endif
cases: incbin CASES_FILE
%ifdef TASK_TEST
%include TASK_CONTEXT_FILE
%include "tests/i386/segments.inc"
%ifdef EXCEPT_TASK_TEST
%include EXCEPT_CONTEXT_FILE
%endif
task_test_control: dd i386_irq_dispatch,i386_idle,segment_test_run
    dd i386_segments_reload,segment_test_gdt+24,segment_test_gdt+32
%ifdef EXCEPT_TASK_TEST
    dd i386_except_invoke,i386_except_resume
%endif
    db 'I32T'
    dd i386_context_switch-$$+512,i386_context_switch_end-i386_context_switch
    dd i386_irq_stubs_begin-$$+512,i386_irq_stubs_end-i386_irq_stubs_begin
    dd irq_test_code_begin-$$+512,irq_test_code_end-irq_test_code_begin
    dd i386_exception_stubs_begin-$$+512,i386_exception_stubs_end-i386_exception_stubs_begin
    dd i386_idle-$$+512,i386_idle_end-i386_idle
    dd segment_test_code_begin-$$+512,segment_test_code_end-segment_test_code_begin
    dd i386_segments_reload-$$+512,i386_segments_reload_end-i386_segments_reload
%ifdef EXCEPT_TASK_TEST
    dd i386_except_context_begin-$$+512,i386_except_context_end-i386_except_context_begin
%endif
%endif
%ifdef IRQ_TEST
    db 'I32Q'
    dd i386_irq_stubs_begin-$$+512,i386_irq_stubs_end-i386_irq_stubs_begin
    dd irq_test_code_begin-$$+512,irq_test_code_end-irq_test_code_begin
    dd i386_exception_stubs_begin-$$+512,i386_exception_stubs_end-i386_exception_stubs_begin
%endif

%ifdef EXCEPT_CONTEXT_TEST
%include EXCEPT_CONTEXT_FILE
%include "tests/i386/except-context.inc"
%include "tests/i386/segments.inc"
except_context_control: dd i386_except_save,i386_except_invoke,i386_except_resume,except_context_test,i386_except_register,segment_test_run,segment_test_gdt+24
    db 'I32E'
    dd i386_except_context_begin-$$+512,i386_except_context_end-i386_except_context_begin
    dd except_context_test_begin-$$+512,except_context_test_end-except_context_test_begin
    dd segment_test_code_begin-$$+512,segment_test_code_end-segment_test_code_begin
%endif
