U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ExportPrompt(U8 *name,U8 *data,I64 size)
{
 U8 *line=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(line);Free(line);
}
U0 AnswerPromptOracle()
{
 CHash *pmt=HashFind("CmdLinePmt",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
 U8 *(*prompt)();
 CDoc *old=Fs->put_doc,*doc;
 U8 *source,*saved,*name,*line;
 I64 size,kind,*records=CAlloc(6*6*8);
 if(!pmt)throw('Prompt');
 if(pmt->type&HTT_FUN)prompt=pmt(CHashFun *)->exe_addr;else prompt=pmt(CHashExport *)->val;
 if(!prompt)throw('Prompt');
 for(kind=0;kind<6;kind++) {
  if(kind==5) {
   while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
   Report("ADAM SERVER READY\n");
  }
  doc=DocNew;Fs->put_doc=doc;Fs->new_answer=FALSE;
  switch(kind) {
   case 0:source="11;22;";break;
   case 1:source="#include \"T:/Values.HC\"";break;
   case 2:source="#include \"T:/VoidEnd.HC\"";break;
   case 3:source="U0 PromptExplicit(){\"MARK\\n\";}PromptExplicit;";break;
   case 5:source="41;Unknown prompt_bad;";break;
   case 4:source="U0 PromptNested(){CDoc *d=DocNew;DocPrint(d,\"11;22;\");ExeDoc(d);DocDel(d);}PromptNested;";break;
  }
  records[kind*6]=ExePutS(source);
  records[kind*6+1]=Fs->answer;records[kind*6+2]=Fs->answer_type;records[kind*6+3]=Fs->new_answer;
  saved=DocSave(doc,&size);name=MStrPrint("before-%d.DD",kind);ExportPrompt(name,saved,size);Free(name);
  In("\n");line=(*prompt)();Free(line);
  records[kind*6+4]=Fs->answer;records[kind*6+5]=Fs->new_answer;
  saved=DocSave(doc,&size);name=MStrPrint("after-%d.DD",kind);ExportPrompt(name,saved,size);Free(name);
  Fs->put_doc=old;DocDel(doc);
 }
 ExportPrompt("prompt-state.bin",records,6*6*8);
 Report("DONE original answer prompt\n");
}
AnswerPromptOracle;
