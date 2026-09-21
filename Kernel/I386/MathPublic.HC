#include "/Kernel/I386/KernelSymbols.HH"
#include "/Kernel/KMathInt.HC"
CI386KernelSymbol math_exports[13];
CHashTable *math_symbols;
Bool I386MathBind(CHashTable *symbols)
{//Publish borrowed kernel-lifetime code once, without heap allocation.
  U32 flags=I386IrqSave;
  I64 i;
  Bool result=FALSE;
  U8 *names="_ROUND\0_TRUNC\0_FLOOR\0_CEIL\0_POW10_I64\0_LN\0_LOG10\0_LOG2\0_FLOOR_U64\0_CEIL_U64\0_ROUND_I64\0_FLOOR_I64\0_CEIL_I64\0",*name=names;
  U8 *addresses[13];
  if(!symbols) goto done;
  if(math_symbols) { result=math_symbols==symbols; goto done; }
  //Check the entire namespace before mutating it.
  for(i=0;i<13;i++) {
    if(HashFind(name,symbols,HTT_EXPORT_SYS_SYM)) goto done;
    while(*name++);
  }
  addresses[0]=&Round;
  addresses[1]=&Trunc;
  addresses[2]=&Floor;
  addresses[3]=&Ceil;
  addresses[4]=&Pow10I64;
  addresses[5]=&Ln;
  addresses[6]=&Log10;
  addresses[7]=&Log2;
  addresses[8]=&FloorU64;
  addresses[9]=&CeilU64;
  addresses[10]=&RoundI64;
  addresses[11]=&FloorI64;
  addresses[12]=&CeilI64;
  name=names;
  for(i=0;i<13;i++) {
    math_exports[i].str=name; math_exports[i].type=HTT_EXPORT_SYS_SYM;
    math_exports[i].kind=1; math_exports[i].val=(addresses[i]+0)(U64);
    HashAdd(&math_exports[i],symbols);
    while(*name++);
  }
  math_symbols=symbols; result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
