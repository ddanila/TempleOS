#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
#assert sizeof(CArcCompress)==17
#assert sizeof(CArcEntry)==16
#assert sizeof(CArcCtrl)==98456
_extern _ARC_ENTRY_GET U0 ArcStep(CArcCtrl *c);
#include "T:/Core.HC"
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  CArcCtrl *c=CAlloc(sizeof(CArcCtrl));
  U64 expected7,expected8;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native compression dictionary\n");
  expected7=ArcCoreTest(c,7); MemSet(c,0,sizeof(CArcCtrl));
  expected8=ArcCoreTest(c,8); Free(c);
  if(expected7!=0xC2BBC609CFFE2505 || expected8!=0xB11B35864A95B67A) { Report("FAIL dictionary oracle\n"); return; }
  line=MStrPrint("ORACLE %X %X\n",expected7,expected8); Report(line); Free(line);
  line=MStrPrint("#define ARC_EXPECTED7 0x%X\n#define ARC_EXPECTED8 0x%X\n%s",expected7,expected8,source);
  Free(source); source=line;
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL compression dictionary compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL compression dictionary link\n"); return; }
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
  Report("DONE native compression dictionary\n");
}
CompileTests;
