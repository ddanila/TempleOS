U0 CPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 CPExport(U8 *name,U8 *bytes,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,bytes,size);CPLog(s);Free(s);}
U0 CPCheck()
{
  CHash *h=HashFind("CmdLinePmt",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
  U8 *(*prompt)();
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*d;
  I64 i,size,rows[24],answer=Fs->answer,type=Fs->answer_type;
  F64 elapsed=Fs->answer_time;Bool pending=Fs->new_answer;
  U8 *input,*line,*text,*name,*cwd=DirCur;
  if(!h){CPLog("COMMAND PROMPT UNAVAILABLE\n");Free(cwd);return;}
  if(h->type&HTT_FUN)prompt=h(CHashFun *)->exe_addr;else prompt=h(CHashExport *)->val;
  if(!prompt){CPLog("COMMAND PROMPT UNAVAILABLE\n");Free(cwd);return;}
  for(i=0;i<6;i++) {
    d=DocNew;Fs->put_doc=d;
    Fs->answer=55;Fs->answer_type=RT_I64;Fs->answer_time=1.25;Fs->new_answer=FALSE;
    input="  6*7;   \n";
    if(i==1){Fs->answer=-7;Fs->new_answer=TRUE;input="abc   \n";}
    if(i==2){Fs->answer=0x400E000000000000;Fs->answer_type=RT_F64;Fs->new_answer=TRUE;input="Print(\"x;\"); \n";}
    if(i==3){Fs->answer=777;Fs->answer_type=RT_U0;Fs->new_answer=TRUE;input=";\n";}
    if(i==4)input="   \n";
    if(i==5){Fs->answer=-1;Fs->answer_type=RT_U64;Fs->new_answer=TRUE;input="#define X 9   \n";}
    In(input);line=(*prompt)();
    rows[i*4]=Fs->answer;rows[i*4+1]=Fs->new_answer;
    rows[i*4+2]=Bt(&Fs->task_flags,TASKf_CMD_LINE_PMT);
    rows[i*4+3]=DocPut==d && DocDisplay==display && DocBorder==border;
    name=MStrPrint("prompt-line-%d.bin",i);CPExport(name,line,StrLen(line));Free(name);
    text=DocSave(d,&size);name=MStrPrint("prompt-doc-%d.DD",i);CPExport(name,text,size);Free(name);
    Sleep(1000);Free(line);Free(text);Fs->put_doc=put;DocDel(d);
  }
  CPExport("prompt-state.bin",rows,sizeof(rows));CPExport("prompt-cwd.bin",cwd,StrLen(cwd));
  Fs->answer=answer;Fs->answer_type=type;Fs->answer_time=elapsed;Fs->new_answer=pending;
  CPLog("COMMAND PROMPT DONE\n");Sleep(1000);Free(cwd);
}
