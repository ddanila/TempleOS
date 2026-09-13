//Compile the original private mapping tables in the x64 test host's scope.
#exe {
  U8 *source=FileRead("/Kernel/SerialDev/Keyboard.HC"),*first,*last;
  first=StrFind("U8 scan_code_map[",source);
  last=StrFind("};",StrFind("U8 num_lock_map[",first))+2;
  *last=0;
  ExePrint("%s",first);
  Free(source);
}
#include "/Kernel/I386/Module.HH"
U0 Report(U8 *s) { while (*s) OutU8(0xE9,*s++); }
U0 CompileTests()
{
  U8 *source=FileRead("T:/Target.HC"),*module,*image,*line;
  I64 size,loaded,errors,i,j,index,flags,oracles=0;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  Report("START native input\n");
  module=CmpI386Module(source,&size,&errors);
  if (!module || errors) {
    source=DocSave(DocPut,&size);
    line=MStrPrint("EXPORT compiler-log.DD %X %X\n",source,size); Report(line);
    Report("FAIL input compile\n"); return;
  }
  image=I386Link(&module,&size,1,&loaded);
  if (!image) { Report("FAIL input link\n"); return; }
  h=module; r=module+h->records_offset;
  Report("LINKED 0\n");
  for (i=0;i<h->record_count;i++,r++) {
    line=NULL;
    if (r->kind==I386_MODULE_DATA_EXPORT && !StrCmp(module+r->name_offset,"char_oracle")) {
      if (r->offset+8+2560>loaded) { Report("FAIL character oracle bounds\n"); return; }
      for (j=0;j<2048;j++) {
        flags=j>>8;
        image[8+r->offset+j]=ScanCode2Char((j&255)|((flags&3)<<9)|((flags&4)<<10));
      }
      for (j=0;j<32768;j++) {
        index=(j&255)+(((j>>9)&3)|((j>>10)&4))*256;
        if (image[8+r->offset+index]!=ScanCode2Char(j)) {
          Report("FAIL character oracle compression\n"); return;
        }
      }
      for (j=0;j<256;j++) {
        flags=scan_code_map[j]; if (!flags) flags=j;
        image[8+r->offset+2048+j]=flags;
        flags=num_lock_map[j]; if (!flags) flags=j;
        image[8+r->offset+2304+j]=flags;
      }
      oracles++;
    }
    if (r->kind==I386_MODULE_EXPORT)
      line=MStrPrint("RANGE 0 %X\n",8+r->offset);
    else if (r->kind==I386_MODULE_DATA_RANGE)
      line=MStrPrint("DATA 0 %X %X\n",8+r->offset,r->name_offset);
    if (line) { Report(line); Free(line); }
  }
  if (oracles!=1) { Report("FAIL character oracle export\n"); return; }
  source=MAlloc(loaded+32);
  source(U32 *)[0]=loaded;
  (source+4)(I64 *)[0]=0;
  (source+12)(I64 *)[0]=0;
  (source+20)(I64 *)[0]=0;
  MemCpy(source+28,image,loaded);
  (source+28+loaded)(U32 *)[0]=0;
  line=MStrPrint("EXPORT expressions.bin %X %X\n",source,loaded+32); Report(line);
  Report("DONE native input\n");
}
CompileTests;
