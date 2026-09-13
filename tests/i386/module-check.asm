; Executes the actual shared HolyC validator on the i386 target.
%include "tests/i386/boot.inc"
%ifndef TEST_NAME
%define TEST_NAME "i386 module validator"
%endif
section stage vstart=0x10000 align=1
bits 32
    cld
    mov ax,16
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    mov esp,0x90000
    mov esi,cases
case_next:
    mov ecx,[esi]
    test ecx,ecx
    jz passed
    mov ebp,esi
    lea esi,[esi+20]
    lea eax,[esi+ecx]
    mov [next_case],eax
    mov edi,0x70000
    rep movsb
    push dword [ebp+8]
    push dword [ebp+4]
    xor eax,eax
    push eax
    cmp dword [ebp+16],0
    jne .null
    mov eax,0x70000
.null:
    push eax
    mov ebx,0x12345678
    call validator
    mov [test_result],eax
    cmp ebx,0x12345678
    jne failed
    cmp esi,[next_case]
    jne failed
    mov ecx,[ebp]
    add ecx,0x70000
    cmp edi,ecx
    jne failed
    cmp esp,0x90000
    jne failed
    test edx,edx
    jnz failed
    cmp eax,[ebp+12]
    jne failed
    inc dword [case_index]
    mov esi,[next_case]
    jmp case_next
passed:
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
passmsg: db 'PASS ',TEST_NAME,10,0
failmsg: db 'FAIL ',TEST_NAME,' ',0
hex_digits: db '0123456789ABCDEF'
case_index: dd 0
next_case: dd 0
test_result: dd 0
validator: incbin VALIDATOR_FILE
cases: incbin CASES_FILE
