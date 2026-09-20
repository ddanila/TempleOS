#include "/Kernel/Types.HH"
extern I64 Words(I64 a);
extern I64 ConditionalPrefix(I64 a);
extern I64 DistinctLabels(I64 a);
extern I64 Loop(I64 a);
extern I64 Branch(I64 a);
extern I64 Entry(I64 a);
extern I64 LocalCall(I64 a);
extern I64 Offset(I64 a);
extern I64 Expression(I64 a);
extern I64 Local(I64 a);
extern I64 Statement(I64 a);
I64 Main(I64 a,I64 b)
{
  if(DistinctLabels(0)!=17 || DistinctLabels(1)!=23) return 11;
  if(ConditionalPrefix(0)!=42 || ConditionalPrefix(1)!=99) return 10;
  if(Words(0)!=0x1234567889ABCDEF) return 1;
  if(Loop(0)!=15) return 2;
  if(Branch(17)!=17) return 3;
  if(Entry(0)!=17) return 4;
  if(LocalCall(0)!=12) return 5;
  if(Offset(0)!=17) return 6;
  if(Expression(0)!=0xFFFFFFFF00000011) return 7;
  if(Local(0)!=23) return 8;
  if(Statement(0)!=29) return 9;
  asm { MOV EBX,123 MOV ESI,456 MOV EDI,789 }
  return 0;
}
I64 Words(I64 a)
{
  asm {
    MOV U32 8[EBP],0x89ABCDEF
    MOV U32 12[EBP],0x12345678
  }
  return a;
}
I64 Loop(I64 a)
{
  asm {
    USE32
    MOV ECX,5
    XOR EAX,EAX
@@10:
    ADD EAX,ECX
    DEC ECX
    JNZ @@10
    MOV U32 8[EBP],EAX
  }
  return a;
}
I64 Branch(I64 a)
{
  asm { JMP done }
  a=99;
done:
  return a;
}
I64 Entry(I64 a)
{
  goto inside;
  asm {
    MOV U32 8[EBP],99
inside:
    MOV U32 8[EBP],17
  }
  return a;
}
I64 LocalCall(I64 a)
{
  asm {
    MOV EAX,5
    CALL @@10
    JMP @@20
@@10:
    ADD EAX,7
    RET
@@20:
    MOV U32 8[EBP],EAX
  }
  return a;
}

I64 Offset(I64 a)
{
  asm { JMP done-7 }
  a=99;
  asm { MOV U32 8[EBP],17 }
done:
  return a;
}
I64 Expression(I64 a)
{
  asm {
    MOV U32 8[EBP],(1<<4)+1
    MOV U32 12[EBP],-1
  }
  return a;
}
I64 Local(I64 a)
{
  I64 value=0;
  asm { MOV U32 &value[EBP],23 }
  return value;
}

I64 Statement(I64 a)
{
  MOV U32 8[EBP],29;
  return a;
}

I64 ConditionalPrefix(I64 a)
{//The false branch must enter the prefix, not the first internal asm label.
  if(a) return 99;
  asm {
    MOV U32 &a[EBP],41
@@10:
    ADD U32 &a[EBP],1
  }
  return a;
}

I64 DistinctLabels(I64 a)
{//Both labels precede IC_ASM in IR, but denote different machine addresses.
  if(a) goto second;
  goto first;
  asm {
    MOV U32 &a[EBP],100
first:
    MOV U32 &a[EBP],17
    JMP done
second:
    MOV U32 &a[EBP],23
done:
  }
  return a;
}
