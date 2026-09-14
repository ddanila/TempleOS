#assert sizeof(CHashSrcSym)==64
#assert sizeof(CHashExport)==72
#assert sizeof(CHashClass)==128
#assert sizeof(CHashFun)==168
#assert sizeof(CHashGlblVar)==136
#assert sizeof(CMemberLst)==144
#include "T:/Values.HC"
#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i,j;
  U64 *oracle=MAlloc(224);
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native symbols\n");
  for(j=0;j<28;j++) oracle[j]=SymbolValueCase(j);
  line=MStrPrint("EXPORT symbol-values.bin %X %X\n",oracle,224); Report(line);
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL symbols compile\n"); return;
  }
  h=module; r=module+h->records_offset;
  for(i=0;i<h->record_count;i++,r++)
    if(r->kind==I386_MODULE_DATA_EXPORT && !StrCmp(module+r->name_offset,"value_oracle")) {
      MemCpy(module+32+r->offset,oracle,224);
    }
  line=MStrPrint("EXPORT symbols.t32m %X %X\n",module,size); Report(line);
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL symbols link\n"); return; }
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
  Report("DONE native symbols\n");
}
CompileTests;
