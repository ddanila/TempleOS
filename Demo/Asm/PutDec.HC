#ifdef I386_PUBLIC_USER_INCLUDED
U64 PutDecDivide10(U64 value,U32 *remainder)
{
  U64 quotient;
  U32 radix=10;
  //Divide the high word, then carry its remainder into the low word.
  asm {
    MOV ECX,U32 &radix[EBP]
    MOV EAX,U32 &value+4[EBP]
    XOR EDX,EDX
    DIV ECX
    MOV U32 &quotient+4[EBP],EAX
    MOV EAX,U32 &value[EBP]
    DIV U32 &radix[EBP]
    MOV U32 &quotient[EBP],EAX
    MOV ECX,U32 &remainder[EBP]
    MOV U32 [ECX],EDX
  }
  return quotient;
}

U0 PutDecU64(U64 value)
{
  U8 digits[21],*cursor=digits+20;
  U32 remainder;
  *cursor=0;
  do {
    value=PutDecDivide10(value,&remainder);
    *--cursor='0'+remainder;
  } while(value);
  PutS(cursor);
}

PutDecU64(122333221);
'\n';
#else
asm {
PUT_DEC_U64::
//RAX is number to print in decimal.
//Preserves all regs.
	PUSH	RBP
	MOV	RBP,RSP
	SUB	RSP,24		//24 char buffer on stack

//$LK,"Save regs",A="FF:::/Kernel/KernelA.HH,PUSH_C_REGS"$ which C code is free to clobber.  We don't have to for C callers,
//but this function will be nice for ASM callers if it saves all regs.
	PUSH_C_REGS

	PUSH	RSI	      //See $LK,"REGG_LOCAL_VARS",A="MN:REGG_LOCAL_VARS"$&$LK,"REGG_LOCAL_NON_PTR_VARS",A="MN:REGG_LOCAL_NON_PTR_VARS"$
	LEA	RSI,-1[RBP]	//Load addr of end of buffer.
				//We picked RSI because of PUT_STR
				//We'll move bwd
	MOV	U8 [RSI],0	//Terminator

	TEST	RAX,RAX		//Special case -- zero
	JNZ	@@05
	DEC	RSI
	MOV	U8 [RSI],'0'
	JMP	@@15

@@05:	MOV	RBX,10		//Divides by 10

@@10:	XOR	RDX,RDX
	DIV	RBX		//RAX=(RDX:RAX)/RBX with remainder in RDX
	ADD	RDX,'0'
	DEC	RSI
	MOV	U8 [RSI],DL
	TEST	RAX,RAX
	JNZ	@@10

@@15:	CALL	PUT_STR
	POP	RSI
	POP_C_REGS
	LEAVE
	RET

_DO_IT::	//The convention is C-callable routines have underscores.
	MOV	RAX,122333221
	CALL	PUT_DEC_U64
	MOV	RAX,'\n'
	CALL	PUT_CHARS
	RET
}

Call(_DO_IT);

#endif
