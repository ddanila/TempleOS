#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U64 specials[16]={0,1,2,0x000FFFFFFFFFFFFF,0x0010000000000000,
    0x7FEFFFFFFFFFFFFF,0x7FF0000000000000,0x7FF0000000000001,0x7FF8000000001234,
    0x3FEFFFFFFFFFFFFF,0x3FF0000000000000,0x3FF0000000000001,
    0x3FF6A09E667F3BCC,0x3FF6A09E667F3BCD,0x4024000000000000,0x4059000000000000};
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  U64 *oracle=MAlloc(32768),bits,seed=0x386F64D;
  F64 value;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native F64 logarithms\n");
  for(i=0;i<1024;i++) {
    if(i<768) bits=(((i/3)(U64)*8)<<52)+(i%3)-1;
    else if(i<800) {
      bits=specials[(i-768)%16];
      if(i>=784) bits|=0x8000000000000000;
    } else {
      seed=seed*6364136223846793005+1442695040888963407;
      bits=seed&0x7FFFFFFFFFFFFFFF;
    }
    oracle[i*4]=bits;
    value=Ln(bits(F64)); oracle[i*4+1]=value(U64);
    value=Log10(bits(F64)); oracle[i*4+2]=value(U64);
    value=Log2(bits(F64)); oracle[i*4+3]=value(U64);
  }
  line=MStrPrint("EXPORT x64-log.bin %X %X\n",oracle,32768); Report(line);
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
  Report("DONE native F64 logarithms\n");
}
CompileTests;
