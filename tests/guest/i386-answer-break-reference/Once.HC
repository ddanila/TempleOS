U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ExportBreak(U8 *name,U8 *data,I64 size)
{
 U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(s);Free(s);
}
U0 AnswerBreakOracle()
{
 CHash *pmt=HashFind("CmdLinePmt",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
 U8 *(*prompt)();
 CDoc *old=Fs->put_doc,*doc;
 U8 *source,*saved,*name,*line;
 I64 size,kind,*records=CAlloc(4*9*8),flags;
 if(!pmt)throw('Prompt');
 if(pmt->type&HTT_FUN)prompt=pmt(CHashFun *)->exe_addr;else prompt=pmt(CHashExport *)->val;
 while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
 Report("ADAM SERVER READY\n");
 for(kind=0;kind<4;kind++) {
  doc=DocNew;Fs->put_doc=doc;Fs->new_answer=FALSE;Fs->answer=7;
  flags=Fs->task_flags;
  switch(kind) {
   case 0:source="41;Break;";break;
   case 1:source="Fs->task_flags|=1<<TASKf_PENDING_BREAK;";break;
   case 2:source="41;Fs->task_flags|=1<<TASKf_PENDING_BREAK;";break;
   case 3:source="U0 PromptUnlock(){Fs->task_flags|=1<<TASKf_PENDING_BREAK;BreakUnlock;}41;PromptUnlock;";break;
  }
  try {records[kind*9]=ExePutS(source);}
  catch {records[kind*9+1]=Fs->except_ch;Fs->catch_except=TRUE;}
  records[kind*9+2]=Fs->answer;records[kind*9+3]=Fs->answer_type;
  records[kind*9+4]=Fs->new_answer;records[kind*9+5]=Fs->task_flags;
  //Capture first, then remove a still-pending synthetic break before inspection.
  Fs->task_flags=(Fs->task_flags&~(1<<TASKf_PENDING_BREAK|1<<TASKf_BREAK_LOCKED))|
    (flags&(1<<TASKf_PENDING_BREAK|1<<TASKf_BREAK_LOCKED));
  saved=DocSave(doc,&size);name=MStrPrint("before-%d.DD",kind);ExportBreak(name,saved,size);Free(name);
  In("\n");line=(*prompt)();Free(line);
  records[kind*9+6]=Fs->answer;records[kind*9+7]=Fs->new_answer;
  records[kind*9+8]=Fs->task_flags;
  saved=DocSave(doc,&size);name=MStrPrint("after-%d.DD",kind);ExportBreak(name,saved,size);Free(name);
  Fs->put_doc=old;DocDel(doc);
 }
 ExportBreak("break-state.bin",records,4*9*8);
 Report("DONE original break prompt\n");
}
AnswerBreakOracle;
