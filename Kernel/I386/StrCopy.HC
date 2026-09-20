//Original Kernel/StrA.HC string-copy semantics with native pointer/stack widths.
U0 MemoryStrCopy(U8 *dst,U8 *src)
{
asm {
USE32
  PUSH ESI
  PUSH EDI
  MOV EDI,U32 8[EBP]
  TEST EDI,EDI
  JZ @@15
  MOV ESI,U32 16[EBP]
  TEST ESI,ESI
  JNZ @@05
  XOR EAX,EAX
  JMP @@10
@@05:
  LODSB
@@10:
  STOSB
  TEST AL,AL
  JNZ @@05
@@15:
  POP EDI
  POP ESI
}
}
