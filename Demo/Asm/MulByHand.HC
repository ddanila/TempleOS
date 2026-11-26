/*When I was a kid with a Commodore 64,
the 6502 chip had no multiply inst
and this is how we had to do it, except,
I used more regs in this example.
*/
class U128
{
  U64 lo,hi;
};

#ifdef I386_PUBLIC_USER_INCLUDED
U16 MulU8(U8 n1,U8 n2)
{
  U32 product;
  asm {
    MOV EAX,U32 &n1[EBP]
    AND EAX,255
    SHL EAX,8
    MOV EDX,U32 &n2[EBP]
    AND EDX,255
    MOV EBX,8
@@step:
    SHL EAX,1
    TEST EAX,0x10000
    JZ @@advance
    //The original ADD AL,BL does not propagate carry to AH.
    MOV ECX,EAX
    AND ECX,255
    ADD ECX,EDX
    AND ECX,255
    AND EAX,0xFF00
    OR EAX,ECX
@@advance:
    DEC EBX
    JNZ @@step
    MOV U32 &product[EBP],EAX
  }
  return product;
}

U64 MulByHandWords(U32 left,U32 right)
{
  U64 product;
  asm {
    MOV EAX,U32 &left[EBP]
    MUL U32 &right[EBP]
    MOV U32 &product[EBP],EAX
    MOV U32 &product+4[EBP],EDX
  }
  return product;
}

U0 MulU64(I64 n1,I64 n2,U128 *product)
{
  U32 a_lo=n1,a_hi=(n1(U64))>>32,b_lo=n2,b_hi=(n2(U64))>>32;
  U64 low=MulByHandWords(a_lo,b_lo);
  U64 middle=(low>>32)+MulByHandWords(a_hi,b_lo);
  U64 combined=(middle&0xFFFFFFFF)+MulByHandWords(a_lo,b_hi);

  //Each middle addition combines a full product with one 32-bit word.
  product->lo=(combined<<32)|(low&0xFFFFFFFF);
  product->hi=MulByHandWords(a_hi,b_hi)+(middle>>32)+(combined>>32);
}
#else
asm {
//Opcodes are slightly different to make writing my x86_64 assembler easier.
//See $LK,"::/Compiler/OpCodes.DD"$.

//You can clobber RAX,RBX,RCX,RDX,R8,R9.  The compiler expects that.

MUL_BY_HAND_U8_U8_TO_U16: //This is only for fun.
//8bit * 8bit-->16bit
//AL*BL-->AX
	MOV	CL,8
	SHL	AX,8
@@05:	SHL1	AX
	JNC	@@10
	ADD	AL,BL
@@10:	DEC	CL
	JNZ	@@05
	RET

_MUL_BY_HAND_U8_U8_TO_U16::	//C callable
	PUSH	RBP
	MOV	RBP,RSP
	MOV	AL,U8 SF_ARG1[RBP] //$LK,"SF_ARG1",A="FF:::/Kernel/KernelA.HH,SF_ARG1"$
	MOV	BL,U8 SF_ARG2[RBP]
	CALL	MUL_BY_HAND_U8_U8_TO_U16
	MOVZX	RAX,AX
	POP	RBP
	RET1	16

_MUL_U64_U64_TO_U128::
//64bit * 64bit-->128bit
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RBX,U64 SF_ARG3[RBP]
	MOV	RAX,U64 SF_ARG1[RBP] //$LK,"SF_ARG1",A="FF:::/Kernel/KernelA.HH,SF_ARG1"$
	MUL	U64 SF_ARG2[RBP]	//Res RDX:RAX 128bit
	MOV	U64 [RBX],RAX
	MOV	U64 8[RBX],RDX
	POP	RBP
	RET1	24
};

//My convention is to put an underscore
//on C callable asm routines.
_extern _MUL_BY_HAND_U8_U8_TO_U16 U16 MulU8(U8 n1,U8 n2);

_extern _MUL_U64_U64_TO_U128 U0 MulU64(I64 n1,I64 n2,U128 *_prod);
#endif

U0 MulByHand()
{
  U128 p;
  "2*7   =0x%X\n",MulU8(2,7);
  "100*10=0x%X\n",MulU8(100,10);

  MulU64(0x0123456789ABCDEF,0x1000001,&p);
  "0x0123466789ABCDEF*0x1000001=0x%016X%016X\n",p.hi,p.lo;
}

MulByHand;

