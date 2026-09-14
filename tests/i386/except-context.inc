; Physical register oracle independent of generated HolyC prologues.
except_context_test_begin:
except_context_test:
    push ebp
    push ebx
    push esi
    push edi
    pushfd
    mov [except_test_stack],esp
    mov ebp,0x10203040
    mov ebx,0x50607080
    mov esi,0x90a0b0c0
    mov edi,0xd0e0f000
    push dword 0x47 ; ZF, PF, CF set, IF and DF clear.
    popfd
    push dword 0
    push dword .resumed
    push dword 0
    push dword .catch
    push dword 0
    push dword except_test_capture
    call i386_except_save
    pushfd
    pop eax
    and eax,0xcd5
    cmp eax,0x45
    jne .bad
    push dword 0x47
    popfd
    push dword 0
    push dword .provider
    push dword 0
    push dword .resumed
    push dword 0
    push dword .catch
    push dword 0
    push dword 0x33334444
    push dword 0
    push dword 0x11112222
    call i386_except_register
    cmp eax,0x12340000
    jne .bad
    cmp edx,0
    jne .bad
    cmp ebp,0x10203040
    jne .bad
    cmp ebx,0x50607080
    jne .bad
    cmp esi,0x90a0b0c0
    jne .bad
    cmp edi,0xd0e0f000
    jne .bad
    mov eax,[except_test_stack]
    cmp [except_test_capture+4],eax
    jne .bad
    cmp dword [except_test_capture],0x10203040
    jne .bad
    cmp dword [except_test_capture+8],0x50607080
    jne .bad
    cmp dword [except_test_capture+12],0x90a0b0c0
    jne .bad
    cmp dword [except_test_capture+16],0xd0e0f000
    jne .bad
    cmp dword [except_test_capture+20],0x47
    jne .bad
    mov ebp,11
    mov ebx,22
    mov esi,33
    mov edi,44
    push dword 2
    popfd
    push dword 0
    push dword except_test_capture
    call i386_except_invoke
    pushfd
    pop eax
    and eax,0xcd5
    cmp eax,0
    jne .bad
    cmp ebp,11
    jne .bad
    cmp ebx,22
    jne .bad
    cmp esi,33
    jne .bad
    cmp edi,44
    jne .bad
    cmp dword [except_test_caught],1
    jne .bad
    ; Abandon a deeper stack, not just a balanced call.
    sub esp,128
    push dword 0
    push dword except_test_capture
    call i386_except_resume
    jmp .bad
.resumed:
    pushfd
    pop eax
    and eax,0xcd5
    cmp eax,0x45
    jne .bad
    cmp esp,[except_test_stack]
    jne .bad
    cmp ebp,0x10203040
    jne .bad
    cmp ebx,0x50607080
    jne .bad
    cmp esi,0x90a0b0c0
    jne .bad
    cmp edi,0xd0e0f000
    jne .bad
    xor eax,eax
    jmp .done
.catch:
    pushfd
    pop eax
    and eax,0xcd5
    cmp eax,0x45
    jne .catch_bad
    cmp ebp,0x10203040
    jne .catch_bad
    cmp ebx,0x50607080
    jne .catch_bad
    cmp esi,0x90a0b0c0
    jne .catch_bad
    cmp edi,0xd0e0f000
    jne .catch_bad
    mov dword [except_test_caught],1
.catch_bad:
    xor ebp,ebp
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
    ret
.bad:
    mov eax,1
.done:
    mov esp,[except_test_stack]
    popfd
    pop edi
    pop esi
    pop ebx
    pop ebp
    mov edx,0
    ret
; Test provider checks argument slots and copies the temporary capture.
.provider:
    cmp dword [esp+4],0x11112222
    jne .provider_bad
    cmp dword [esp+12],0x33334444
    jne .provider_bad
    mov edx,[esp+20]
%assign capture_offset 0
%rep 8
    mov eax,[edx+capture_offset]
    mov [except_test_capture+capture_offset],eax
%assign capture_offset capture_offset+4
%endrep
    mov eax,0x12340000
    mov edx,0
    ret 24
.provider_bad:
    mov eax,0
    mov edx,0
    ret 24
except_context_test_end:
align 4
except_test_stack: dd 0
except_test_capture: times 8 dd 0
except_test_caught: dd 0
