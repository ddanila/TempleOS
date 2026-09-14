#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U8 *NameDefault(U8 *name,U8 *extension) { return ExtDft(name,extension); }
U8 *NameToggle(U8 *name) { return ToggleZorNotZ(name); }
U0 NameFree(U8 *name) { Free(name); }
#include "T:/Names.HC"
U8 *PathDir(U8 *name) { return DirNameAbs(name); }
U8 *PathFile(U8 *name) { return FileNameAbs(name); }
U0 PathContextSet(U8 *directory,U8 *home) { Fs->cur_dir=directory; blkdev.home_dir=home; }
#include "T:/Paths.HC"
I64 OriginalPathsTest()
{
  U8 *old_dir=Fs->cur_dir,*old_home=blkdev.home_dir;
  I64 result,old_boot=blkdev.boot_drv_let;
  if(Drv2Let!='T') return 99;
  Fs->cur_dir="/Work/Here"; blkdev.home_dir="H:/Users/Test"; blkdev.boot_drv_let='B';
  result=PathRulesTest;
  if(!result) result=PathContextTest;
  if(!result) result=PathLiteralTest;
  Fs->cur_dir=old_dir; blkdev.home_dir=old_home; blkdev.boot_drv_let=old_boot;
  return result;
}
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native RedSea\n");
  if(NameRulesTest) { Report("FAIL original filename rules\n"); return; }
  Report("PASS original filename rules\n");
  i=OriginalPathsTest;
  if(i) { line=MStrPrint("FAIL original paths %d\n",i); Report(line); return; }
  Report("PASS original paths\n");
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL RedSea compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL RedSea link\n"); return; }
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
  Report("DONE native RedSea\n");
}
CompileTests;
