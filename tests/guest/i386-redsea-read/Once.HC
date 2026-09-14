#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 ExportReadFiles()
{
  U8 *pattern="// Native disk include fixture.\n",*function="I64 Twice(I64 x) { return x*2; }\n",*source,*line;
  I64 i,size=64*StrLen(pattern)+StrLen(function);
  CArcCompress *arc;
  source=MAlloc(size);
  for(i=0;i<size;i++) {
    if(i<64*StrLen(pattern)) source[i]=pattern[i%StrLen(pattern)];
    else source[i]=function[i-64*StrLen(pattern)];
  }
  arc=CompressBuf(source,size);
  if(arc->compression_type!=CT_7_BIT) { Report("FAIL source compression mode\n"); return; }
  line=MStrPrint("EXPORT packed-source.bin %X %X\n",arc,arc->compressed_size); Report(line);
  source=MAlloc(4096); for(i=0;i<4096;i++) source[i]=i;
  arc=CompressBuf(source,4096);
  if(arc->compression_type!=CT_8_BIT) { Report("FAIL binary compression mode\n"); return; }
  line=MStrPrint("EXPORT packed-binary.bin %X %X\n",arc,arc->compressed_size); Report(line);
}
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native decoded RedSea reads\n");
  ExportReadFiles;
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL decoded RedSea reads compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL decoded RedSea reads link\n"); return; }
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
  Report("DONE native decoded RedSea reads\n");
}
CompileTests;
