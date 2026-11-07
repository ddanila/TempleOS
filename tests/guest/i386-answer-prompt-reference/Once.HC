U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ExportPrompt(U8 *name,U8 *data,I64 size)
{
 U8 *line=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(line);Free(line);
}
I64 PromptStreamCount=0;
U0 AnswerPromptOracle()
{
 CHash *pmt=HashFind("CmdLinePmt",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
 U8 *(*prompt)();
 CDoc *old=Fs->put_doc,*doc;
 U8 *source,*saved,*name,*line;
 I64 size,kind,*records=CAlloc(17*6*8);
 if(!pmt)throw('Prompt');
 if(pmt->type&HTT_FUN)prompt=pmt(CHashFun *)->exe_addr;else prompt=pmt(CHashExport *)->val;
 if(!prompt)throw('Prompt');
 for(kind=0;kind<17;kind++) {
  if(kind==5) {
   while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
   Report("ADAM SERVER READY\n");
  }
  doc=DocNew;Fs->put_doc=doc;Fs->new_answer=FALSE;
  if(kind>=10){Fs->answer=7;Fs->answer_type=RT_I64;}
  switch(kind) {
   case 9:source=MStrPrint("#include \"%C:/AnswerDirs/Outer.HC\"",Drv2Let);break;
   case 10:source="#exe{123;}";break;
   case 11:source="#exe{1.5+2.25;}";break;
   case 12:source="#exe{0(U8 *);}";break;
   case 13:source="7;#exe{123;}";break;
   case 14:source="7;#exe{1.5+2.25;}";break;
   case 15:source="7;#exe{0(U8 *);}";break;
   case 16:source="#exe{PromptStreamCount=PromptStreamCount+1;}";break;
   case 0:source="11;22;";break;
   case 1:source=MStrPrint("#include \"%C:/Values.HC\"",Drv2Let);break;
   case 2:source=MStrPrint("#include \"%C:/VoidEnd.HC\"",Drv2Let);break;
   case 3:source="U0 PromptExplicit(){\"MARK\\n\";}PromptExplicit;";break;
   case 7:source="CDoc *PromptInitFloatDoc=DocNew;DocPrint(PromptInitFloatDoc,\"1.5+2.25;\");F64 PromptInitFloat=ExeDoc(PromptInitFloatDoc)(F64);";break;
   case 8:source="CDoc *PromptInitPointerDoc=DocNew;DocPrint(PromptInitPointerDoc,\"0(U8 *);\");U8 *PromptInitPointer=ExeDoc(PromptInitPointerDoc)(U8 *);";break;
   case 6:source="CDoc *PromptInitDoc=DocNew;DocPrint(PromptInitDoc,\"11;22;\");I64 PromptInitValue=ExeDoc(PromptInitDoc);";break;
   case 5:source="41;Unknown prompt_bad;";break;
   case 4:source="U0 PromptNested(){CDoc *d=DocNew;DocPrint(d,\"11;22;\");ExeDoc(d);DocDel(d);}PromptNested;";break;
  }
  records[kind*6]=ExePutS(source);
  if(kind==16 && PromptStreamCount!=1)throw;
  if(kind==1 || kind==2 || kind==9)Free(source);
  records[kind*6+1]=Fs->answer;records[kind*6+2]=Fs->answer_type;records[kind*6+3]=Fs->new_answer;
  saved=DocSave(doc,&size);name=MStrPrint("before-%d.DD",kind);ExportPrompt(name,saved,size);Free(name);
  In("\n");line=(*prompt)();Free(line);
  records[kind*6+4]=Fs->answer;records[kind*6+5]=Fs->new_answer;
  saved=DocSave(doc,&size);name=MStrPrint("after-%d.DD",kind);ExportPrompt(name,saved,size);Free(name);
  Fs->put_doc=old;DocDel(doc);
 }
 ExportPrompt("prompt-state.bin",records,17*6*8);
 Report("DONE original answer prompt\n");
}
AnswerPromptOracle;
