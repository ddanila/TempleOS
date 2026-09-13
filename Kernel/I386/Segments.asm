; U0 reload(U16 fs,U16 gs), normal eight-byte HolyC arguments. IF must be clear.
; Caller has installed valid descriptors; reload hidden bases/limits after edits.
bits 32
i386_segments_code_begin:
i386_segments_reload:
    mov eax,[esp+4]
    mov fs,ax
    mov eax,[esp+12]
    mov gs,ax
    ret 16
i386_segments_code_end:
