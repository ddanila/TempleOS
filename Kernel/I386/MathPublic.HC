#include "/Kernel/I386/KernelSymbols.HH"
#include "/Kernel/KMathInt.HC"
CI386KernelSymbol math_exports[30];
CHashTable *math_symbols;
U64 (*i386_power_implementation)(U64 base,U64 exponent);

U8 *I386PowerLoader(U8 *name)
{
  CI386KernelSymbol *symbol=HashFind(name,I386TaskSelf->hash_table,HTT_EXPORT_SYS_SYM);
  if (symbol && symbol->kind==1) return symbol->val;
  return 0;
}

I64 I386PowerLoad()
{//Adam checks readiness before loading and borrows only published code.
  I64 (*load_file)(U8 *filename,Bool warn_extension);
  CHashFun *implementation;
  if (!i386_power_implementation && (load_file=I386PowerLoader("_ADAM_FILE"))) {
    (*load_file)("::/Kernel/I386/FloatPower.HC",FALSE);
    implementation=HashFind("I386PowerImplementation",I386TaskSelf->hash_table,HTT_FUN);
    if (implementation) i386_power_implementation=implementation->exe_addr;
  }
  return 0;
}

U64 I386F64Power(U64 base,U64 exponent)
{
  CI386Task *task;
  I64 (*adam)(U8 *format,...);
  if (!i386_power_implementation) {
    task=I386TaskSelf;
    if (task==task->owner->root)
      I386PowerLoad;
    else if (adam=I386PowerLoader("_ADAM"))
      (*adam)("Call(0x%X);",&I386PowerLoad);
    if (!i386_power_implementation) throw('PowLoad',TRUE);
  }
  return (*i386_power_implementation)(base,exponent);
}

U8 *math_addresses[30]={
  &Round,&Trunc,&Floor,&Ceil,&Pow10I64,
  &Ln,&Log10,&Log2,&FloorU64,&CeilU64,
  &RoundI64,&FloorI64,&CeilI64,&I386F64Sqrt,&I386F64Abs,
  &I386F64Add,&I386F64Sub,&I386F64Mul,&I386F64Div,&I386F64Mod,
  &I386F64FromI64,&I386F64ToI64,&I386F64Compare,&Sin,&Cos,
  &Arg,&Exp,&I386F64Power,&I386F64MulToI64,&I386F64PiMulDiv
};

Bool I386MathBind(CHashTable *symbols)
{//Publish borrowed kernel-lifetime code once, without heap allocation.
  U32 flags=I386IrqSave;
  I64 i;
  U64 bias;
  Bool result=FALSE;
  U8 *names="_ROUND\0_TRUNC\0_FLOOR\0_CEIL\0_POW10_I64\0_LN\0_LOG10\0_LOG2\0_FLOOR_U64\0_CEIL_U64\0_ROUND_I64\0_FLOOR_I64\0_CEIL_I64\0I386F64Sqrt\0I386F64Abs\0I386F64Add\0I386F64Sub\0I386F64Mul\0I386F64Div\0I386F64Mod\0I386F64FromI64\0I386F64ToI64\0I386F64Compare\0_SIN\0_COS\0_ARG\0_EXP\0I386F64Power\0I386F64MulToI64\0I386F64PiMulDiv\0",*name=names;
  if(!symbols) goto done;
  if(math_symbols) { result=math_symbols==symbols; goto done; }
  //Check the entire namespace before mutating it.
  for(i=0;i<30;i++) {
    if(HashFind(name,symbols,HTT_EXPORT_SYS_SYM)) goto done;
    while(*name++);
  }
  //Cross-built data slots hold local offsets. Native relocations may
  //already have placed them at their runtime addresses.
  bias=(&Round-math_addresses[0])(U64);
  name=names;
  for(i=0;i<30;i++) {
    math_exports[i].str=name; math_exports[i].type=HTT_EXPORT_SYS_SYM;
    math_exports[i].kind=1; math_exports[i].val=(math_addresses[i]+0)(U64)+bias;
    HashAdd(&math_exports[i],symbols);
    while(*name++);
  }
  math_symbols=symbols; result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
