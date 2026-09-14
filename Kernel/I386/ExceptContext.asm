; Bootstrap native exception context primitives. Flat ring 0, eight-byte args.
; Layout is CI386ExceptCapture in Except.HH. Caller validates lifetime/bounds.
; No allocation, task lookup, record removal, or exception policy here.
bits 32
i386_except_context_begin:
; U0 save(CI386ExceptCapture *out,U8 *catch_start,U8 *untry_start)
; Capture at entry, before any preserved register or flags are changed.
i386_except_save:
    mov eax,[esp+4]
    mov [eax],ebp
    lea edx,[esp+28]
    mov [eax+4],edx
    mov [eax+8],ebx
    mov [eax+12],esi
    mov [eax+16],edi
    pushfd
    pop edx
    mov [eax+20],edx
    mov edx,[esp+12]
    mov [eax+24],edx
    mov edx,[esp+20]
    mov [eax+28],edx
    ret 24
; U0 invoke(CI386ExceptCapture *capture)
; A compiler catch block ends with a bare RET. Run it on the throwing stack
; with the enclosing EBP and preserved registers, then restore the invoker.
i386_except_invoke:
    pushfd
    push ebp
    push ebx
    push esi
    push edi
    mov eax,[esp+24]
    mov ebp,[eax]
    mov ebx,[eax+8]
    mov esi,[eax+12]
    mov edi,[eax+16]
    push dword [eax+20]
    popfd
    call [eax+24]
    pop edi
    pop esi
    pop ebx
    pop ebp
    popfd
    ret 8
; U0 resume(CI386ExceptCapture *capture), does not return.
; Read all fields before switching ESP: the capture may be on the old stack.
i386_except_resume:
    mov eax,[esp+4]
    mov ebp,[eax]
    mov ebx,[eax+8]
    mov esi,[eax+12]
    mov edi,[eax+16]
    mov ecx,[eax+4]
    mov edx,[eax+28]
    push dword [eax+20]
    popfd
    mov esp,ecx
    jmp edx
; CI386Except *register(task,heap,catch_start,untry_start,push_provider)
; Five eight-byte arguments; provider has I386ExceptPush's three-argument ABI.
; Capture on the stack before calling any HolyC code. Failure returns NULL.
i386_except_register:
    lea esp,[esp-32]
    mov [esp],ebp
    lea eax,[esp+76]
    mov [esp+4],eax
    mov [esp+8],ebx
    mov [esp+12],esi
    mov [esp+16],edi
    pushfd
    pop eax
    mov [esp+20],eax
    mov eax,[esp+52]
    mov [esp+24],eax
    mov eax,[esp+60]
    mov [esp+28],eax
    mov eax,esp
    mov ecx,[esp+44]
    mov edx,[esp+36]
    push dword 0
    push eax
    push dword 0
    push ecx
    push dword 0
    push edx
    call [esp+92]
    lea esp,[esp+32]
    xor edx,edx
    ret 40
i386_except_context_end:
