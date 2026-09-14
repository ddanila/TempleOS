#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U64 math_inputs[32]={
    0x0000000000000000, 0x0000000000000001, 0x0000000000000002, 0x0000000000000003,
    0x000000000000007F, 0x0000000000000080, 0x00000000000000FF, 0x0000000000000100,
    0x0000000000007FFF, 0x0000000000008000, 0x000000000000FFFF, 0x0000000000010000,
    0x000000007FFFFFFF, 0x0000000080000000, 0x00000000FFFFFFFF, 0x0000000100000000,
    0x0000000100000001, 0x7FFFFFFFFFFFFFFF, 0x8000000000000000, 0x8000000000000001,
    0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFF00000000, 0xFFFFFFFF00000001,
    0x4000000000000000, 0x4000000000000001, 0x0000000200000001, 0x123456789ABCDEF0,
    0xFEDCBA9876543210, 0xAAAAAAAAAAAAAAAA, 0x5555555555555555, 0x000000010000FFFF
};
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i,j;
  U64 *oracle=MAlloc(98304),*row,a,b,quotient;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native integer math\n");
  for (i=0;i<32;i++) for (j=0;j<32;j++) {
    a=math_inputs[i]; b=math_inputs[j]; row=oracle+(i*32+j)*12;
    row[0]=a; row[1]=b;
    row[2]=AbsI64(a); row[3]=SignI64(a);
    row[4]=MinI64(a,b); row[5]=MaxI64(a,b);
    row[6]=MinU64(a,b); row[7]=MaxU64(a,b);
    row[8]=SqrI64(a); row[9]=SqrU64(a);
    row[10]=row[11]=0;
    if (b) { quotient=a; row[11]=ModU64(&quotient,b); row[10]=quotient; }
  }
  line=MStrPrint("EXPORT x64-integer-math.bin %X %X\n",oracle,98304); Report(line);
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL integer math compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL integer math link\n"); return; }
  h=module; r=module+h->records_offset;
  Report("LINKED 0\n");
  for (i=0;i<h->record_count;i++,r++) {
    if (r->kind==I386_MODULE_DATA_EXPORT && !StrCmp(module+r->name_offset,"math_oracle")) {
      line=MStrPrint("ORACLE %X %X\n",28+8+r->offset,98304); Report(line); Free(line);
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
  Report("DONE native integer math\n");
}
CompileTests;
