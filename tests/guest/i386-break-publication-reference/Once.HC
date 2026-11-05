U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ExportPublication(U8 *name,U8 *data,I64 size)
{
 U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(s);Free(s);
}
U0 PublicationOracle()
{
 CDoc *old=Fs->put_doc,*doc;
 CHashFun *fun;
 I64 (*call)();
 U8 *source,*name,*data,*output;
 I64 kind,size,flags,*records=CAlloc(8*9*8);
 while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
 Report("ADAM SERVER READY\n");
 for(kind=0;kind<8;kind++) {
  doc=DocNew;Fs->put_doc=doc;Fs->answer=7;Fs->new_answer=FALSE;flags=Fs->task_flags;
  name=MStrPrint("OriginalPub%02d",kind);
  switch(kind%4) {
   case 0:source=MStrPrint("I64 %s(){return 99;}41;Break;",name);break;
   case 1:source=MStrPrint("I64 %s(){return 99;}41;throw('Delib',TRUE);",name);break;
   case 2:source=MStrPrint("I64 %s(){return 99;}41;Unknown after_break;",name);break;
   case 3:source=MStrPrint("I64 %s(){return 99;}Fs->task_flags|=1<<TASKf_PENDING_BREAK;",name);break;
  }
  try {records[kind*9]=ExePutS(source,,(kind/4)*CCF_CMD_LINE);}
  catch {records[kind*9+1]=Fs->except_ch;Fs->catch_except=TRUE;}
  records[kind*9+2]=Fs->answer;records[kind*9+3]=Fs->answer_type;
  records[kind*9+4]=Fs->new_answer;records[kind*9+5]=Fs->task_flags;
  //Inspect publication only after recording and clearing a synthetic pending bit.
  Fs->task_flags=(Fs->task_flags&~(1<<TASKf_PENDING_BREAK))|(flags&(1<<TASKf_PENDING_BREAK));
  fun=HashFind(name,Fs->hash_table,HTT_FUN);
  records[kind*9+6]=fun && fun->exe_addr;
  records[kind*9+7]=-1;
  if(fun && fun->exe_addr) {call=fun->exe_addr;records[kind*9+7]=(*call)();}
  records[kind*9+8]=Fs->answer;
  data=DocSave(doc,&size);output=MStrPrint("output-%d.DD",kind);ExportPublication(output,data,size);Free(output);
  Fs->put_doc=old;DocDel(doc);
 }
 ExportPublication("publication.bin",records,8*9*8);
 Report("DONE original break publication\n");
}
PublicationOracle;
