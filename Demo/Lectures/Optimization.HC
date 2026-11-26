/*The moral of this story is simple
inst level optimizations
don't matter much on a modern Intel CPU
because they convert complex insts
to a stream of RISC insts.

I learned this the hard way when I thought
I was greatly improving my compiler by
cutting code by a third.  No significant
speed-up.  Depressing.
*/

#define SAMPLES	(8*10000000+1)

#ifdef I386_PUBLIC_USER_INCLUDED
I64 Loop1()
{
  I64 result;
  U32 limit=SAMPLES;
  asm {
    XOR EAX,EAX
    XOR EBX,EBX
    MOV ECX,1
@@05:
    MOV ESI,ECX
    INC ECX
    ADD EAX,ESI
    ADC EBX,0
    LEA EDI,U32 &limit-16[EBP]
    CMP ECX,U32 16[EDI]
    JB @@05
    MOV U32 &result[EBP],EAX
    MOV U32 &result+4[EBP],EBX
  }
  return result;
}

I64 Loop2()
{
  I64 result;
  asm {
    XOR EAX,EAX
    XOR EBX,EBX
    MOV ECX,SAMPLES-1
@@05:
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    JNZ @@05
    MOV U32 &result[EBP],EAX
    MOV U32 &result+4[EBP],EBX
  }
  return result;
}

I64 Loop3()
{
  I64 result;
  asm {
    XOR EAX,EAX
    XOR EBX,EBX
    MOV ECX,SAMPLES-1
@@05:
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    ADD EAX,ECX
    ADC EBX,0
    DEC ECX
    JNZ @@05
    MOV U32 &result[EBP],EAX
    MOV U32 &result+4[EBP],EBX
  }
  return result;
}

I64 Loop4()
{
  I64 result;
  asm {
    XOR EAX,EAX
    XOR EBX,EBX
    MOV ECX,SAMPLES-1
@@05:
    ADD EAX,ECX
    ADC EBX,0
    LOOP @@05
    MOV U32 &result[EBP],EAX
    MOV U32 &result+4[EBP],EBX
  }
  return result;
}

#else
asm {

LIMIT::	DU64	SAMPLES;	//Memory reference should be bad, right?

_BADLY_UNOPTIMIZED::
	MOV	RAX,0
	MOV	RCX,1
@@05:	MOV	RDX,RCX
	INC	RCX		//if no dependencies, Free!
	ADD	RAX,RDX
	MOV	RDX,LIMIT-16	//added 16 displacement to make it worse
	CMP	RCX,U64 16[RDX]
	JB	@@05
	RET

_WELL_OPTIMIZED1::
	XOR	RAX,RAX
	MOV	RCX,SAMPLES-1
@@05:	ADD	RAX,RCX
	DEC	RCX
	JNZ	@@05
	RET

_WELL_OPTIMIZED2:: //Unrolled
	XOR	RAX,RAX
	MOV	RCX,SAMPLES-1
@@05:	ADD	RAX,RCX
	DEC	RCX
	ADD	RAX,RCX
	DEC	RCX
	ADD	RAX,RCX
	DEC	RCX
	ADD	RAX,RCX
	DEC	RCX
	ADD	RAX,RCX
	DEC	RCX
	ADD	RAX,RCX
	DEC	RCX
	ADD	RAX,RCX
	DEC	RCX
	ADD	RAX,RCX
	DEC	RCX
	JNZ	@@05
	RET

_WELL_OPTIMIZED3::
	XOR	RAX,RAX
	MOV	RCX,SAMPLES-1
@@05:	ADD	RAX,RCX
	LOOP	@@05	//Inst has slow speed, but saves code size.
	RET
}

_extern _BADLY_UNOPTIMIZED I64 Loop1();
_extern _WELL_OPTIMIZED1   I64 Loop2();
_extern _WELL_OPTIMIZED2   I64 Loop3();
_extern _WELL_OPTIMIZED3   I64 Loop4();
#endif

I64 i;
F64 t0;

#ifdef I386_PUBLIC_USER_INCLUDED
"%03X Cores %d Hz counter\n",mp_cnt,cnts.time_stamp_freq;
#else
CPURep;
#endif

"Bad Code\n";
t0=tS;
i=Loop1;
"Res:%d Time:%9.6f\n",i,tS-t0;

"Good Code #1\n";
t0=tS;
i=Loop2;
"Res:%d Time:%9.6f\n",i,tS-t0;

"Good Code #2\n";
t0=tS;
i=Loop3;
"Res:%d Time:%9.6f\n",i,tS-t0;

"Good Code #3\n";
t0=tS;
i=Loop4;
"Res:%d Time:%9.6f\n",i,tS-t0;

/*  Program Output$HL,0$$WW+H,1$$FD,1$
8 Cores 2.660GHz
Bad Code
Res:3200000040000000 Time: 0.069966
Good Code #1
Res:3200000040000000 Time: 0.062567
Good Code #2
Res:3200000040000000 Time: 0.062907
Good Code #3
Res:3200000040000000 Time: 0.156359
$HL,1$*/
