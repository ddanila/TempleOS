#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
Bool Reject(U8 *body)
{
  U8 *source=MStrPrint("#include \"/Kernel/Types.HH\"\n#define TRUE 1\n#define FALSE 0\n%s\n#include \"/Kernel/I386/SoftF64.HC\"\n",body),*module;
  I64 size,errors;
  module=CmpI386Module(source,&size,&errors); Free(source);
  if (module) { Free(module); return FALSE; }
  return TRUE;
}
#include "T:/Conditions.HC"
#include "T:/Chains.HC"
#include "T:/ModInputs.HC"
#include "T:/Bitwise.HC"
#include "T:/BitwiseMixed.HC"
#include "T:/ModUpdates.HC"
Bool CheckMixedHost()
{
  I64 whole=7,*values=MAlloc(64);
  F64 step=2.5;
  I8 narrow=-127;
  U8 byte_value=250;
  U64 bits=0xFFFFFFFFFFFFFFFF;
  I8 *narrow_ptr=&narrow;
  U8 *byte_ptr=&byte_value;
  U8 *line;
  whole+=step; values[0]=whole;
  whole-=step; values[1]=whole;
  whole*=step; values[2]=whole;
  whole/=step; values[3]=whole;
  whole=-7; whole+=step; values[4]=whole;
  *narrow_ptr-=step; values[5]=*narrow_ptr;
  bits+=step; values[6]=bits;
  step=10.5; *byte_ptr+=step; values[7]=*byte_ptr;
  line=MStrPrint("EXPORT x64-mixed.bin %X %X\n",values,64); Report(line);
  return values[0]==9 && values[1]==6 && values[2]==15 && values[3]==6 &&
    values[4]==-4 && values[5]==127 && values[6]==1 && values[7]==4;
}
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  U64 *mod_values=MAlloc(49152),*bit_values=MAlloc(245760),*mixed_bits=MAlloc(425984),mod_a,mod_b,mod_seed=0x386F64D;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native F64 expressions\n");
  for(i=0;i<2048;i++) {
    ModInputs(i,&mod_seed,&mod_a,&mod_b);
    mod_values[i*3]=mod_a; mod_values[i*3+1]=mod_b;
    mod_values[i*3+2]=HostModBits(mod_a,mod_b);
    BitwiseValues(mod_a,mod_b,bit_values+i*15);
    MixedBitwiseValues(mod_a,mod_b,mixed_bits+i*26);
  }
  Report(MStrPrint("EXPORT x64-mod.bin %X %X\n",mod_values,49152));
  Report(MStrPrint("EXPORT x64-bitwise.bin %X %X\n",bit_values,245760));
  Report(MStrPrint("EXPORT x64-bitwise-mixed.bin %X %X\n",mixed_bits,425984));
  i=CheckBitwiseDestinations(-129);
  if(i) { Report(MStrPrint("FAIL x64 bitwise destinations %d picks=%d byte=%d result=%d\n",i,bitwise_picks,bitwise_byte,bitwise_result)); return; }
  Report(MStrPrint("OBSERVED x64 narrow XOR update: stored=%d result=%d\n",bitwise_byte,bitwise_result));
  Report("PASS four x64 bitwise destination checks\n");
  i=CheckModUpdates();
  if(i) { Report(MStrPrint("FAIL x64 remainder updates %d\n",i)); return; }
  Report("PASS eleven x64 remainder update checks\n");
  if (!CheckMixedHost()) { Report("FAIL x64 mixed update contract\n"); return; }
  Report("PASS eight x64 mixed update checks\n");
  Report(MStrPrint("OBSERVED x64 (!F64_zero)+2: %d\n",ConditionNotArithmetic(0.0)));
  i=CheckConditions();
  if (i) { Report(MStrPrint("FAIL x64 conditions %d\n",i)); return; }
  Report("PASS 144 x64 condition pairs and 12 loop cases\n");
  Report(MStrPrint("OBSERVED x64 0.0<I64_one<minimum_subnormal: %d\n",
    ChainMixedMiddle(0.0,1,0x0000000000000001(F64))));
  i=CheckChains(FALSE);
  if (i) { Report(MStrPrint("FAIL x64 chains %d\n",i)); return; }
  Report(MStrPrint("OBSERVED x64 chain differences: branch=%d mixed-middle=%d\n",
    chain_float_branch_differences,chain_mixed_middle_differences));
  if (chain_float_branch_differences!=29 || chain_mixed_middle_differences!=130) {
    Report("FAIL changed x64 chain compatibility observations\n"); return;
  }
  Report("PASS 512 x64 chain triples with recorded differences\n");
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL F64 compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL F64 link\n"); return; }
  h=module; r=module+h->records_offset;
  Report("LINKED 0\n");
  for (i=0;i<h->record_count;i++,r++) {
    if(r->kind==I386_MODULE_DATA_EXPORT && !StrCmp(module+r->name_offset,"f64_mod_oracle"))
      Report(MStrPrint("ORACLE %X %X\n",28+8+r->offset,49152));
    line=NULL;
    if (r->kind==I386_MODULE_EXPORT)
      line=MStrPrint("RANGE 0 %X\n",8+r->offset);
    else if (r->kind==I386_MODULE_DATA_RANGE)
      line=MStrPrint("DATA 0 %X %X\n",8+r->offset,r->name_offset);
    if (line) { Report(line); Free(line); }
  }
  source=MAlloc(loaded+32);
  source(U32 *)[0]=loaded;
  (source+4)(I64 *)[0]=0;
  (source+12)(I64 *)[0]=0;
  (source+20)(I64 *)[0]=0;
  MemCpy(source+28,image,loaded);
  (source+28+loaded)(U32 *)[0]=0;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",source,loaded+32); Report(line);
  if (!Reject("F64 Main(F64 a,F64 b) { return a+b; }") ||
      !Reject("extern I64 I386F64Mod(U64 a,U64 b); F64 Main(F64 a,F64 b) { return a%b; }") ||
      !Reject("extern U64 I386F64Mod(I64 a,U64 b); F64 Main(F64 a,F64 b) { return a%b; }") ||
      !Reject("#include \"/Kernel/I386/SoftF64.HH\"\nF64 Main(F64 a,F64 b) { return a`b; }") ||
      !Reject("#include \"/Kernel/I386/SoftF64.HH\"\nF64 Main(F64 a) { return ~a; }") ||
      !Reject("F64 Main(F64 a,F64 b) { return a%b; }") ||
      !Reject("extern I64 I386F64Add(U64 a,U64 b); F64 Main(F64 a,F64 b) { return a+b; }") ||
      !Reject("extern U64 I386F64Add(I64 a,U64 b); F64 Main(F64 a,F64 b) { return a+b; }")) {
    Report("FAIL unsupported F64 accepted\n"); return;
  }
  Report("PASS eight unsupported F64 checks\n");
  Report("DONE native F64 expressions\n");
}
CompileTests;
