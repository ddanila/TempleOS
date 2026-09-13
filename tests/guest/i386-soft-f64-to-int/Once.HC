#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U64 conversion_special[8]={0,1,0x000FFFFFFFFFFFFF,0x0010000000000000,
  0x7FEFFFFFFFFFFFFF,0x7FF0000000000000,0x7FF0000000000001,0x7FF8000000001234};
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  U64 *oracle=MAlloc(16384),bits,seed=0x386F64C;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native F64 to integer\n");
  for (i=0;i<1024;i++) {
    seed=seed*6364136223846793005+1442695040888963407;
    if (i<768) {
      bits=((1023+i/12)(U64)<<52)+(i%6)-2;
      if (i%12>=6) bits|=0x8000000000000000;
    } else if (i<784) {
      bits=conversion_special[(i-768)%8];
      if (i>=776) bits|=0x8000000000000000;
    } else bits=seed;
    oracle[i*2]=bits;
    oracle[i*2+1]=ToI64(bits(F64));
  }
  line=MStrPrint("EXPORT x64-to-int.bin %X %X\n",oracle,16384); Report(line);
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
      line=MStrPrint("ORACLE %X %X\n",28+8+r->offset,16384); Report(line); Free(line);
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
  Report("DONE native F64 to integer\n");
}
CompileTests;
