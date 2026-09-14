#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U64 signed_inputs[8]={0,1,0xFFFFFFFFFFFFFFFF,0x8000000000000000,
  0x7FFFFFFFFFFFFFFF,0x0020000000000001,0xFFE0000000000001,0x8000000000000001};
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  U64 *signed_oracle=MAlloc(128);
  F64 value;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native integer to F64\n");
  for (i=0;i<8;i++) {
    signed_oracle[i*2]=signed_inputs[i];
    value=ToF64(signed_inputs[i]);
    signed_oracle[i*2+1]=value(U64);
  }
  line=MStrPrint("EXPORT x64-from-int.bin %X %X\n",signed_oracle,128); Report(line);
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
      line=MStrPrint("ORACLE %X %X\n",28+8+r->offset,24576); Report(line); Free(line);
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
  Report("DONE native integer to F64\n");
}
CompileTests;
