U0 CSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 CSCase(I64 index,U8 *source)
{
  I64 errors,main_count=0,offset=-1,log_size;
  CAOT *aot=CmpI386Buf(source,&errors);CAOTImportExport *ie;U8 *s,*log;
  if(!aot || errors){
    log=DocSave(DocPut,&log_size);s=MStrPrint("EXPORT compiler-log.DD %X %X\n",log,log_size);CSLog(s);
    CSLog("FAIL cross statement compilation\n");throw;
  }
  for(ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next)
    if(ie->type==IET_MAIN){main_count++;offset=ie->rip;}
    else {CSLog("FAIL unexpected cross statement relocation\n");throw;}
  if(main_count!=1 || offset<0 || offset>=aot->aot_U8s || aot->abss || aot->heap_glbls){CSLog("FAIL cross statement metadata\n");throw;}
  s=MStrPrint("CROSS STATEMENT %d %X %X\n",index,offset,aot->aot_U8s);CSLog(s);Free(s);
  s=MStrPrint("EXPORT cross-statement-%d.bin %X %X\n",index,aot->buf,aot->aot_U8s);CSLog(s);Free(s);
  //Retain these isolated AOT records until VM exit; this is not a heap oracle.
}
U0 CSReject()
{
  I64 errors,log_size;CAOT *aot;U8 *log,*s;
  while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
  aot=CmpI386Buf("_intern 0x64 U0 CrossUnsupported(U8 *a);CrossUnsupported(0);",&errors);
  if(aot || !errors){CSLog("FAIL accepted unsupported cross statement\n");throw;}
  log=DocSave(DocPut,&log_size);
  s=MStrPrint("EXPORT rejected-statement.DD %X %X\n",log,log_size);CSLog(s);Free(s);
  CSLog("CROSS REJECT unsupported instruction\n");
}
CSLog("START cross statements\n");
CSReject;
CSCase(0,"6*7;");
CSCase(1,"0x123456789ABCDEF;");
CSCase(2,"2+3,6*7;");
CSCase(3,"{3;6*7;}");
CSCase(4,"1.25+2.5;");
CSCase(5,"(0x123456789ABCDEF<<13)^0x7FEDCBA987654321;");
CSLog("DONE cross statements\n");
