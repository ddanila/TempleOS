//Native provider for the compiler's two-argument SysTry ABI.
//Enter must copy the capture before returning TRUE. Failure must recover or stop.
#include "/Kernel/Types.HH"
asm {
USE32
IMPORT I386ExceptEnter,I386ExceptRegistrationFailed;
SysTry::
  LEA ESP,U32 -32[ESP]
  MOV U32 [ESP],EBP
  LEA EAX,U32 52[ESP]
  MOV U32 4[ESP],EAX
  MOV U32 8[ESP],EBX
  MOV U32 12[ESP],ESI
  MOV U32 16[ESP],EDI
  PUSHFD
  POP EAX
  MOV U32 20[ESP],EAX
  MOV EAX,U32 36[ESP]
  MOV U32 24[ESP],EAX
  MOV EAX,U32 44[ESP]
  MOV U32 28[ESP],EAX
  MOV EAX,ESP
  PUSH 0
  PUSH EAX
  CALL I386ExceptEnter
  TEST EAX,EAX
  JNZ @@10
  CALL I386ExceptRegistrationFailed
@@20:
  JMP @@20
@@10:
  LEA ESP,U32 32[ESP]
  RET1 16
}
