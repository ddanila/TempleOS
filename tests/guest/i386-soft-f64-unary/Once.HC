#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
Bool RejectUnary(U8 *body)
{
  U8 *source=MStrPrint("#include \"/Kernel/Types.HH\"\n#include \"/Kernel/I386/Float.HH\"\n%s\n",body),*module;
  I64 size,errors;
  module=CmpI386Module(source,&size,&errors); Free(source);
  if (module) { Free(module); return FALSE; }
  return TRUE;
}
U64 unary_special[16]={0,1,2,0x000FFFFFFFFFFFFF,0x0010000000000000,
  0x1E5FFFFFFFFFFFFF,0x1E60000000000000,0x1E60000000000001,
  0x3FE0000000000000,0x3FF8000000000000,0x5FEFFFFFFFFFFFFF,0x5FF0000000000000,
  0x7FEFFFFFFFFFFFFF,0x7FF0000000000000,0x7FF0000000000001,0x7FF8000000001234};
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  U64 *oracle=MAlloc(32768),bits,seed=0x386F64A;
  F64 value;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native F64 unary\n");
  for (i=0;i<1024;i++) {
    seed=seed*6364136223846793005+1442695040888963407;
    if (i<768) {
      bits=(((i/6)(U64)*16)<<52)+(i%3)-1;
      if (i%6>=3) bits|=0x8000000000000000;
    } else if (i<800) {
      bits=unary_special[(i-768)%16];
      if (i>=784) bits|=0x8000000000000000;
    } else bits=seed;
    oracle[i*4]=bits;
    value=Abs(bits(F64)); oracle[i*4+1]=value(U64);
    value=Sqr(bits(F64)); oracle[i*4+2]=value(U64);
    value=Sqrt(bits(F64)); oracle[i*4+3]=value(U64);
  }
  line=MStrPrint("EXPORT x64-unary.bin %X %X\n",oracle,32768); Report(line);
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL software F64 compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL software F64 link\n"); return; }
  h=module; r=module+h->records_offset;
  Report("LINKED 0\n");
  for (i=0;i<h->record_count;i++,r++) {
    if (r->kind==I386_MODULE_DATA_EXPORT && !StrCmp(module+r->name_offset,"f64_oracle")) {
      line=MStrPrint("ORACLE %X %X\n",28+8+r->offset,32768); Report(line); Free(line);
    }
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
  if (!RejectUnary("F64 Main(F64 a) { return Abs(a); }") ||
      !RejectUnary("extern U64 I386F64Abs(I64 a); F64 Main(F64 a) { return Abs(a); }") ||
      !RejectUnary("extern I64 I386F64Abs(U64 a); F64 Main(F64 a) { return Abs(a); }") ||
      !RejectUnary("F64 Main(F64 a) { return Sqr(a); }") ||
      !RejectUnary("F64 Main(F64 a) { return Sqrt(a); }") ||
      !RejectUnary("extern U64 I386F64Sqrt(I64 a); F64 Main(F64 a) { return Sqrt(a); }")) {
    Report("FAIL malformed unary runtime accepted\n"); return;
  }
  Report("PASS six unary runtime rejection checks\n");
  Report("DONE native F64 unary\n");
}
CompileTests;
