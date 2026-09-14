//Native single-CPU task context, idle and segment reload entries.
#include "/Kernel/Types.HH"
asm {
USE32
// U0 switch(CI386Context *old,CI386Context *next), eight-byte argument slots.
// Flat ring 0, IF clear; caller owns contexts/stacks and scheduling policy.
// Same address space. No FPU/debug-register state or CPU/task descriptor update.
i386_context_switch::
  PUSHFD
  PUSHAD
  PUSH DS
  PUSH ES
  PUSH FS
  PUSH GS
  MOV EAX,U32 +56[ESP]
  MOV EDX,U32 +64[ESP]
  MOV U32 [EAX],ESP
  MOV ESP,U32 [EDX]
  POP GS
  POP FS
  POP ES
  POP DS
  POPAD
  POPFD
  RET1 16
// U0 idle(): caller has IF clear and has checked runnable work on this CPU.
// An installed, unmasked interrupt source must be able to wake the CPU.
// STI's interrupt shadow covers HLT; return with IF clear after wakeup.
i386_idle::
  STI
  HLT
  CLI
  RET
// U0 reload(U16 fs,U16 gs), normal eight-byte HolyC arguments. IF must be clear.
// Caller has installed valid descriptors; reload hidden bases/limits after edits.
i386_segments_reload::
  MOV EAX,U32 +4[ESP]
  MOV FS,AX
  MOV EAX,U32 +12[ESP]
  MOV GS,AX
  RET1 16
}
