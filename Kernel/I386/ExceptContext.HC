//Native exception context primitives; flat ring 0, eight-byte arguments.
#include "/Kernel/Types.HH"
asm {
USE32
// Layout is CI386ExceptCapture in Except.HH. Caller validates lifetime/bounds.
// No allocation, task lookup, record removal, or exception policy here.
// U0 save(CI386ExceptCapture *out,U8 *catch_start,U8 *untry_start)
// Capture at entry, before any preserved register or flags are changed.
i386_except_save::
  MOV EAX,U32 +4[ESP]
  MOV U32 [EAX],EBP
  LEA EDX,U32 +28[ESP]
  MOV U32 +4[EAX],EDX
  MOV U32 +8[EAX],EBX
  MOV U32 +12[EAX],ESI
  MOV U32 +16[EAX],EDI
  PUSHFD
  POP EDX
  MOV U32 +20[EAX],EDX
  MOV EDX,U32 +12[ESP]
  MOV U32 +24[EAX],EDX
  MOV EDX,U32 +20[ESP]
  MOV U32 +28[EAX],EDX
  RET1 24
// U0 invoke(CI386ExceptCapture *capture)
// A compiler catch block ends with a bare RET. Run it on the throwing stack
// with the enclosing EBP and preserved registers, then restore the invoker.
i386_except_invoke::
  PUSHFD
  PUSH EBP
  PUSH EBX
  PUSH ESI
  PUSH EDI
  MOV EAX,U32 +24[ESP]
  MOV EBP,U32 [EAX]
  MOV EBX,U32 +8[EAX]
  MOV ESI,U32 +12[EAX]
  MOV EDI,U32 +16[EAX]
  PUSH U32 +20[EAX]
  POPFD
  CALL U32 +24[EAX]
  POP EDI
  POP ESI
  POP EBX
  POP EBP
  POPFD
  RET1 8
// U0 resume(CI386ExceptCapture *capture), does not return.
// Read all fields before switching ESP: the capture may be on the old stack.
i386_except_resume::
  MOV EAX,U32 +4[ESP]
  MOV EBP,U32 [EAX]
  MOV EBX,U32 +8[EAX]
  MOV ESI,U32 +12[EAX]
  MOV EDI,U32 +16[EAX]
  MOV ECX,U32 +4[EAX]
  MOV EDX,U32 +28[EAX]
  PUSH U32 +20[EAX]
  POPFD
  MOV ESP,ECX
  JMP EDX
// CI386Except *register(task,heap,catch_start,untry_start,push_provider)
// Five eight-byte arguments; provider has I386ExceptPush's three-argument ABI.
// Capture on the stack before calling any HolyC code. Failure returns NULL.
i386_except_register::
  LEA ESP,U32 -32[ESP]
  MOV U32 [ESP],EBP
  LEA EAX,U32 +76[ESP]
  MOV U32 +4[ESP],EAX
  MOV U32 +8[ESP],EBX
  MOV U32 +12[ESP],ESI
  MOV U32 +16[ESP],EDI
  PUSHFD
  POP EAX
  MOV U32 +20[ESP],EAX
  MOV EAX,U32 +52[ESP]
  MOV U32 +24[ESP],EAX
  MOV EAX,U32 +60[ESP]
  MOV U32 +28[ESP],EAX
  MOV EAX,ESP
  MOV ECX,U32 +44[ESP]
  MOV EDX,U32 +36[ESP]
  PUSH 0
  PUSH EAX
  PUSH 0
  PUSH ECX
  PUSH 0
  PUSH EDX
  CALL U32 +92[ESP]
  LEA ESP,U32 +32[ESP]
  XOR EDX,EDX
  RET1 40
}
