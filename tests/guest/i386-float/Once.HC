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
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native F64 expressions\n");
  if (!CheckMixedHost()) { Report("FAIL x64 mixed update contract\n"); return; }
  Report("PASS eight x64 mixed update checks\n");
  Report(MStrPrint("OBSERVED x64 (!F64_zero)+2: %d\n",ConditionNotArithmetic(0.0)));
  i=CheckConditions();
  if (i) { Report(MStrPrint("FAIL x64 conditions %d\n",i)); return; }
  Report("PASS 144 x64 condition pairs and 12 loop cases\n");
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
      !Reject("#include \"/Kernel/I386/SoftF64.HH\"\nF64 Main(F64 a,I64 b) { return a%b; }") ||
      !Reject("#include \"/Kernel/I386/SoftF64.HH\"\nI64 Main(I64 a,F64 b) { a%=b; return a; }") ||
      !Reject("#include \"/Kernel/I386/SoftF64.HH\"\nI64 Main(F64 a,F64 b) { return a<b<0.0; }") ||
      !Reject("#include \"/Kernel/I386/SoftF64.HH\"\nF64 Main(F64 a,F64 b) { return a&b; }") ||
      !Reject("#include \"/Kernel/I386/SoftF64.HH\"\nF64 Main(F64 a,F64 b) { return a%b; }") ||
      !Reject("extern I64 I386F64Add(U64 a,U64 b); F64 Main(F64 a,F64 b) { return a+b; }") ||
      !Reject("extern U64 I386F64Add(I64 a,U64 b); F64 Main(F64 a,F64 b) { return a+b; }")) {
    Report("FAIL unsupported F64 accepted\n"); return;
  }
  Report("PASS eight unsupported F64 checks\n");
  Report("DONE native F64 expressions\n");
}
CompileTests;
