; U0 idle(): caller has IF clear and has checked runnable work on this CPU.
; An installed, unmasked interrupt source must be able to wake the CPU.
; STI's interrupt shadow covers HLT; return with IF clear after wakeup.
bits 32
i386_idle_code_begin:
i386_idle:
    sti
    hlt
    cli
    ret
i386_idle_code_end:
