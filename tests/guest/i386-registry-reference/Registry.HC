I64 RGValue;
I64 RGContract(I64 drive)
{
  CDoc *doc=RGDoc();CTask *owner=NULL;I64 mask=0,count;U8 *line,*name,*old_name;
  Bool old_silent=Silent(TRUE);
  if(!doc){Silent(old_silent);return 0;}
  old_name=StrNew(doc->filename.name);name=MStrPrint("%c:/RegistryTest.HC.Z",drive);
  RGDelete(name);StrCpy(doc->filename.name,name);RGValue=0;
  if(!RegDft("Codex/RegistryTest","RGValue=11;\n"))mask|=1;
  if(doc->mem_task==adam_task)mask|=2;
  if(RegDft("Codex/RegistryTest","RGValue=999;\n"))mask|=4;
  RegExe("Codex/RegistryTest");if(RGValue==11)mask|=8;
  if(RegWrite("Codex/RegistryTest","RGValue=21;\n")) {
    RGValue=0;RegExe("Codex/RegistryTest");if(RGValue==21)mask|=16;
  }
  if(RegAppend("Codex/RegistryTest","RGValue+=5;\n")) {
    RGValue=0;RegExe("Codex/RegistryTest");if(RGValue==26)mask|=32;
  }
  count=RegCnt("Codex/RegistryTest");
  if(count>=2&&DocTreeFFind(name,"Codex/RegistryTest"))mask|=64;
  if(DocTreeFind(doc,"Codex/RegistryTest"))mask|=128;
  owner=doc->mem_task;
  line=MStrPrint("REGISTRY OWNER %X %X %X COUNT %d MASK %d\n",owner,adam_task,Fs,count,mask);Report(line);Free(line);
  StrCpy(doc->filename.name,old_name);RGDelete(name);Free(old_name);Free(name);
  Silent(old_silent);return mask;
}
I64 RGCheck(I64 drive){I64 v=RGContract(drive);if(v!=255)throw('Registry',TRUE);return v;}
