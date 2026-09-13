// Relocatable i386 division template, assembled by HolyC on the compiler host.
// EDX:EAX dividend, EBX:ECX divisor, ESI flags (bit 0 signed, bit 1 remainder).
// Preserves EBP/ESP; other scratch registers belong to the enclosing emitter.
asm {
USE32
I386_DIV_BEGIN::
  PUSH EBP
  MOV EBP,ESP
  SUB ESP,16
  MOV U32 -4[EBP],ESI
  MOV EDI,EBX
  OR EDI,ECX
  JNZ @@05
  XOR ESI,ESI
  DIV ESI
@@05:
  TEST ESI,1
  JZ @@30
  CMP EDX,-0x80000000
  JNZ @@10
  TEST EAX,EAX
  JNZ @@10
  CMP EBX,-1
  JNZ @@10
  CMP ECX,-1
  JNZ @@10
  XOR ESI,ESI
  DIV ESI
@@10:
  MOV U32 -8[EBP],EDX
  MOV ESI,EDX
  XOR ESI,EBX
  MOV U32 -12[EBP],ESI
  TEST EDX,EDX
  JNS @@20
  NEG EAX
  ADC EDX,0
  NEG EDX
@@20:
  TEST EBX,EBX
  JNS @@30
  NEG ECX
  ADC EBX,0
  NEG EBX
@@30:
  XOR ESI,ESI
  XOR EDI,EDI
  MOV U32 -16[EBP],64
@@40:
  SHL EAX,1
  RCL EDX,1
  RCL ESI,1
  RCL EDI,1
  JC @@50
  CMP EDI,EBX
  JB @@60
  JA @@50
  CMP ESI,ECX
  JB @@60
@@50:
  SUB ESI,ECX
  SBB EDI,EBX
  OR EAX,1
@@60:
  DEC U32 -16[EBP]
  JNZ @@40
  TEST U32 -4[EBP],2
  JZ @@70
  MOV EAX,ESI
  MOV EDX,EDI
  MOV ESI,U32 -8[EBP]
  JMP @@75
@@70:
  MOV ESI,U32 -12[EBP]
@@75:
  TEST U32 -4[EBP],1
  JZ @@80
  TEST ESI,ESI
  JNS @@80
  NEG EAX
  ADC EDX,0
  NEG EDX
@@80:
  MOV ESP,EBP
  POP EBP
I386_DIV_END::
USE64
}
_extern I386_DIV_BEGIN U8 i386_div_begin[1];
_extern I386_DIV_END U8 i386_div_end[1];
