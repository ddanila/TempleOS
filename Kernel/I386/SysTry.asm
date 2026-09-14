; Bootstrap T32M provider for the compiler's two-argument SysTry call.
; Native HolyC providers:
;   Bool I386ExceptEnter(CI386ExceptCapture *capture)
;   U0 I386ExceptRegistrationFailed() -- must transfer to recovery or terminate.
; Enter copies the temporary capture into an owned record before returning true.
; No fall-through into the try body is possible after failed registration.
bits 32
    dd 0x4D323354
    dw 2
    db 3,4
    dd 1,module_end,code_end-code,3,records,strings
code:
sys_try:
    lea esp,[esp-32]
    mov [esp],ebp
    lea eax,[esp+52]
    mov [esp+4],eax
    mov [esp+8],ebx
    mov [esp+12],esi
    mov [esp+16],edi
    pushfd
    pop eax
    mov [esp+20],eax
    mov eax,[esp+36]
    mov [esp+24],eax
    mov eax,[esp+44]
    mov [esp+28],eax
    mov eax,esp
    push dword 0
    push eax
    db 0xe8
enter_fixup: dd 0
    test eax,eax
    jnz registered
    db 0xe8
failed_fixup: dd 0
.stop:
    jmp .stop
registered:
    lea esp,[esp+32]
    ret 16
    times (-($-code)) & 7 db 0
code_end:
records:
    dd 1,sys_try-code,name_try,6
    dd 2,enter_fixup-code,name_enter,15
    dd 2,failed_fixup-code,name_failed,28
strings:
name_try: db 'SysTry',0
name_enter: db 'I386ExceptEnter',0
name_failed: db 'I386ExceptRegistrationFailed',0
module_end:
