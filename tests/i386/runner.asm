%include "tests/i386/boot.inc"

; This section is loaded at 0x10000, hence labels need that virtual origin.
section stage vstart=0x10000 align=1
bits 32
    cld
    mov ax,16
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    lidt [idt_ptr]
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
    push dword [esi+24]
    push dword [esi+20]
    push dword [esi+16]
    push dword [esi+12]
    lea eax,[esi+28]
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
    mov eax,0x10
    out 0xf4,eax
    jmp stop
failed:
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
%ifdef FUNCTIONS
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
cases: incbin CASES_FILE
