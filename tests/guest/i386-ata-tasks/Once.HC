#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line,*modules[3];
  I64 size,loaded,errors,i,j,base=8,sizes[3];
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native ata tasks\n");
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL tasks compile\n"); return;
  }
  modules[0]=module;sizes[0]=size;
  source=FileRead("/Kernel/I386/SysTry.HC");
  modules[1]=CmpI386Module(source,&sizes[1],&errors);Free(source);
  if(!modules[1] || errors) { Report("FAIL HolyC SysTry provider compile\n");return; }
  line=MStrPrint("EXPORT SysTry.t32m %X %X\n",modules[1],sizes[1]);Report(line);Free(line);
  source=FileRead("/Kernel/I386/ExceptContext.HC");
  modules[2]=CmpI386Module(source,&sizes[2],&errors);Free(source);
  if(!modules[2] || errors) { Report("FAIL HolyC exception context compile\n");return; }
  line=MStrPrint("EXPORT ExceptContext.t32m %X %X\n",modules[2],sizes[2]);Report(line);Free(line);
  source=FileRead("/Kernel/I386/TaskContext.HC");
  image=CmpI386Module(source,&loaded,&errors);
  Free(source);
  if(!image || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL HolyC task context compile\n"); return;
  }
  line=MStrPrint("EXPORT TaskContext.t32m %X %X\n",image,loaded); Report(line);
  Free(image);
  source=FileRead("/Kernel/I386/IrqEntry.HC");
  image=CmpI386Module(source,&loaded,&errors);
  Free(source);
  if(!image || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL HolyC IrqEntry compile\n"); return;
  }
  line=MStrPrint("EXPORT IrqEntry.t32m %X %X\n",image,loaded); Report(line);
  Free(image);
  source=FileRead("/Kernel/I386/ExceptionEntry.HC");
  image=CmpI386Module(source,&loaded,&errors);
  Free(source);
  if(!image || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL HolyC ExceptionEntry compile\n"); return;
  }
  line=MStrPrint("EXPORT ExceptionEntry.t32m %X %X\n",image,loaded); Report(line);
  Free(image);
  image=I386Link(modules,sizes,3,&loaded);
  if (!image) { Report("FAIL tasks link\n"); return; }
  Report("LINKED 0\n");
  for(j=0;j<3;j++) {
  h=modules[j];r=modules[j]+h->records_offset;
  //The exception context includes a nonreturning resume entry; audit its
  //complete assembly unit, as in the dedicated real exception-task fixture.
  if(j==2) {
    line=MStrPrint("RANGE 0 %X\n",base);Report(line);Free(line);
  } else for (i=0;i<h->record_count;i++,r++) {
    line=NULL;
    if (r->kind==I386_MODULE_EXPORT)
      line=MStrPrint("RANGE 0 %X\n",base+r->offset);
    else if (r->kind==I386_MODULE_DATA_EXPORT &&
        !StrCmp(modules[j]+r->name_offset,"ata_task_record_bytes"))
      line=MStrPrint("ATA TASK RECORD BYTES %d\n",(image+base+r->offset)(I64 *)[0]);
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
  Report("DONE native ata tasks\n");
}
try CompileTests;
catch {
  U8 *saved_doc,*failure_line;I64 saved_size;
  saved_doc=DocSave(DocPut,&saved_size);
  failure_line=MStrPrint("EXPORT compiler-log.DD %X %X\n",saved_doc,saved_size);Report(failure_line);
  Report("FAIL ATA fixture compiler exception\n");
}
