#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
Bool EmitCase(U8 *name,U8 *provider,I64 case_number,I64 expected,I64 a,I64 b,U8 **cursor)
{
  U8 *source,*modules[2],*image,*line,*p=*cursor;
  I64 sizes[2],loaded,errors,i,j,count=1,base=8;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  if (provider) count=2;
  for (i=0;i<count;i++) {
    if (i) source=FileRead(provider);
    else source=FileRead(name);
    modules[i]=CmpI386Module(source,&sizes[i],&errors);
    if (!modules[i] || errors) {
      source=DocSave(DocPut,&loaded);
      line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,loaded); Report(line);
      Report("FAIL module set compile\n"); return FALSE;
    }
    if (case_number==1) {
      if (i) line=MStrPrint("EXPORT provider.t32m %X %X\n",modules[i],sizes[i]);
      else line=MStrPrint("EXPORT consumer.t32m %X %X\n",modules[i],sizes[i]);
      Report(line);
    }
  }
  image=I386Link(modules,sizes,count,&loaded);
  if (!image || loaded>0x30000) { Report("FAIL module set link\n"); return FALSE; }
  line=MStrPrint("LINKED %d\n",case_number); Report(line);
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++) {
      line=NULL;
      if (r->kind==I386_MODULE_EXPORT)
        line=MStrPrint("RANGE %d %X\n",case_number,base+r->offset);
      else if (r->kind==I386_MODULE_DATA_RANGE)
        line=MStrPrint("DATA %d %X %X\n",case_number,base+r->offset,r->name_offset);
      if (line) { Report(line); Free(line); }
    }
    base+=h->code_size;
  }
  p(U32 *)[0]=loaded;
  (p+4)(I64 *)[0]=expected; (p+12)(I64 *)[0]=a; (p+20)(I64 *)[0]=b;
  MemCpy(p+28,image,loaded); *cursor=p+28+loaded;
  return TRUE;
}
U0 CompileTests()
{
  U8 *packet=MAlloc(0x80000),*cursor=packet,*line;
  Report("START native RedSea module set\n");
  if (!EmitCase("T:/Target.HC",NULL,0,0,0,0,&cursor) ||
      !EmitCase("T:/Consumer.HC","T:/Provider.HC",1,0x10000004C,17,25,&cursor)) return;
  cursor(U32 *)[0]=0;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",packet,cursor-packet+4); Report(line);
  Report("DONE native RedSea module set\n");
}
CompileTests;
