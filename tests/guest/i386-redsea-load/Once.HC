#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
Bool EmitCase(U8 *name,I64 case_number,I64 expected,I64 a,I64 b,U8 **cursor)
{
  U8 *source=FileRead(name),*module,*image,*line,*p=*cursor;
  I64 size,loaded,errors,i;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL disk module compile\n"); return FALSE;
  }
  if (case_number==1) {
    line=MStrPrint("EXPORT payload.t32m %X %X\n",module,size); Report(line);
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image || loaded>0x30000) { Report("FAIL disk module link\n"); return FALSE; }
  h=module; r=module+h->records_offset;
  line=MStrPrint("LINKED %d\n",case_number); Report(line);
  for (i=0;i<h->record_count;i++,r++) {
    line=NULL;
    if (r->kind==I386_MODULE_EXPORT)
      line=MStrPrint("RANGE %d %X\n",case_number,8+r->offset);
    else if (r->kind==I386_MODULE_DATA_RANGE)
      line=MStrPrint("DATA %d %X %X\n",case_number,8+r->offset,r->name_offset);
    if (line) { Report(line); Free(line); }
  }
  p(U32 *)[0]=loaded;
  (p+4)(I64 *)[0]=expected; (p+12)(I64 *)[0]=a; (p+20)(I64 *)[0]=b;
  MemCpy(p+28,image,loaded); *cursor=p+28+loaded;
  return TRUE;
}
U0 CompileTests()
{
  U8 *packet=MAlloc(0x80000),*cursor=packet,*line;
  Report("START native RedSea module load\n");
  if (!EmitCase("T:/Target.HC",0,0,0,0,&cursor) ||
      !EmitCase("T:/Payload.HC",1,0x10000002A,17,25,&cursor)) return;
  cursor(U32 *)[0]=0;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",packet,cursor-packet+4); Report(line);
  Report("DONE native RedSea module load\n");
}
CompileTests;
