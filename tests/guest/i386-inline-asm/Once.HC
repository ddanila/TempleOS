#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
Bool Reject(U8 *body)
{
  Report("REJECT "); Report(body); Report("\n");
  I64 size,errors;
  U8 *source=MStrPrint("#include \"/Kernel/Types.HH\"\nI64 Bad() { %s return 0; }",body),*module;
  module=CmpI386Module(source,&size,&errors);
  Free(source);
  if(module || !errors) { Report("FAIL unsupported inline asm accepted\n"); return FALSE; }
  return TRUE;
}
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native inline asm\n");
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL inline asm compile\n"); return;
  }
  Report("PASS inline asm compile\n");
  if(!Reject("asm { USE16 NOP }") || !Reject("asm { USE64 NOP }") ||
      !Reject("asm { MOV RAX,1 }") || !Reject("asm { MOV R8D,1 }") ||
      !Reject("asm { MOV EAX,U32 [RAX] }") ||
      !Reject("asm { MOV EAX,@@10 @@10: NOP }") ||
      !Reject("asm { IMPORT Missing; CALL Missing }")) return;
  Report("PASS inline asm rejections\n");
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL inline asm link\n"); return; }
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
  Report("DONE native inline asm\n");
}
CompileTests;
