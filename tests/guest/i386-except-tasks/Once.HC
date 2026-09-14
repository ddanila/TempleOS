#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line,*modules[2];
  I64 size,loaded,errors,i,j,base=8,sizes[2];
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native exception tasks\n");
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL exception tasks compile\n"); return;
  }
  modules[0]=module; sizes[0]=size;
  source=FileRead("/Kernel/I386/SysTry.HC");
  modules[1]=CmpI386Module(source,&sizes[1],&errors);
  Free(source);
  if(!modules[1] || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL HolyC SysTry provider compile\n"); return;
  }
  line=MStrPrint("EXPORT SysTry.t32m %X %X\n",modules[1],sizes[1]); Report(line);
  image=I386Link(modules,sizes,2,&loaded);
  if (!image) { Report("FAIL exception tasks link\n"); return; }
  Report("LINKED 0\n");
  for(j=0;j<2;j++) {
  h=modules[j]; r=modules[j]+h->records_offset;
  for (i=0;i<h->record_count;i++,r++) {
    line=NULL;
    if (r->kind==I386_MODULE_EXPORT)
      line=MStrPrint("RANGE 0 %X\n",base+r->offset);
    else if (r->kind==I386_MODULE_DATA_RANGE)
      line=MStrPrint("DATA 0 %X %X\n",base+r->offset,r->name_offset);
    if (line) { Report(line); Free(line); }
  }
  base+=h->code_size;
  }
  source=MAlloc(loaded+32);
  source(U32 *)[0]=loaded;
  (source+4)(I64 *)[0]=0;
  (source+12)(I64 *)[0]=0;
  (source+20)(I64 *)[0]=0;
  MemCpy(source+28,image,loaded);
  (source+28+loaded)(U32 *)[0]=0;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",source,loaded+32); Report(line);
  Report("DONE native exception tasks\n");
}
CompileTests;
