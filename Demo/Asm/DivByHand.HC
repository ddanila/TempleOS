#ifdef I386_PUBLIC_USER_INCLUDED
I64 DivU64ByU64(I64 dividend,I64 divisor)
{
  I64 quotient;
  //EBX:EAX holds the dividend and the growing quotient.
  //ESI:EDX holds the running remainder.
  asm {
    MOV EAX,U32 &dividend[EBP]
    MOV EBX,U32 &dividend+4[EBP]
    XOR EDX,EDX
    XOR ESI,ESI
    MOV ECX,64
@@step:
    SHL ESI,1
    SHL EDX,1
    JNC @@next_bit
    INC ESI
@@next_bit:
    TEST EBX,0x80000000
    JZ @@shift_quotient
    INC EDX
@@shift_quotient:
    SHL EBX,1
    SHL EAX,1
    JNC @@compare
    INC EBX
@@compare:
    CMP ESI,U32 &divisor+4[EBP]
    JB @@advance
    JA @@subtract
    CMP EDX,U32 &divisor[EBP]
    JB @@advance
@@subtract:
    SUB EDX,U32 &divisor[EBP]
    JNC @@high_word
    DEC ESI
@@high_word:
    SUB ESI,U32 &divisor+4[EBP]
    INC EAX
@@advance:
    DEC ECX
    JNZ @@step
    MOV U32 &quotient[EBP],EAX
    MOV U32 &quotient+4[EBP],EBX
  }
  return quotient;
}
#else
asm {
_DIV_U64_BY_U64::
	PUSH	RBP
	MOV	RBP,RSP
	XOR	RDX,RDX
	MOV	RCX,64
	MOV	RAX,SF_ARG1[RBP]
	MOV	RBX,SF_ARG2[RBP]
@@1:	SHL1	RAX
	RCL1	RDX
	CMP	RBX,RDX
	JA	@@2
	INC	RAX
	SUB	RDX,RBX
@@2:	LOOP	@@1
	POP	RBP
	RET1	16
}

_extern _DIV_U64_BY_U64 I64 DivU64ByU64(I64 dividend,I64 divisor);
#endif

"123456/10=%d\n",DivU64ByU64(123456,10);
