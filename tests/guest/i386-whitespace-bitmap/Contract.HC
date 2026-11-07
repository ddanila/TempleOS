U0 WBLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 WBCheck()
{
  CHash *h=HashFind("CmdLinePmt",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
  U8 *(*prompt)();U8 *line=NULL,*value=NULL,*s;
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*d;
  U32 saved[16];I64 mask=0,answer=Fs->answer,type=Fs->answer_type;
  F64 elapsed=Fs->answer_time;Bool pending=Fs->new_answer;
  if(!h){WBLog("WHITESPACE UNAVAILABLE\n");return;}
  if(h->type&HTT_FUN)prompt=h(CHashFun *)->exe_addr;else prompt=h(CHashExport *)->val;
  if(!prompt){WBLog("WHITESPACE UNAVAILABLE\n");return;}
  MemCpy(saved,char_bmp_white_space,sizeof(saved));d=DocNew;Fs->put_doc=d;
  try {
    LBts(char_bmp_white_space,'!');
    if(Str2I64("!!42")==42)mask|=1;
    if(Str2F64("!!3.75")==3.75)mask|=2;
    value=StrNew("!!word!!");StrUtil(value,SUF_REM_LEADING|SUF_REM_TRAILING);
    if(!StrCmp(value,"word"))mask|=4;
    Fs->new_answer=FALSE;In("42;!!\n");line=(*prompt)();
    if(!StrCmp(line,"42;;\n"))mask|=8;
    if(DocPut==d && DocDisplay==display && DocBorder==border &&
       !Bt(&Fs->task_flags,TASKf_CMD_LINE_PMT))mask|=16;
  } catch {
    MemCpy(char_bmp_white_space,saved,sizeof(saved));
    Fs->put_doc=put;DocDel(d);Free(value);Free(line);
    Fs->answer=answer;Fs->answer_type=type;Fs->answer_time=elapsed;Fs->new_answer=pending;
  }
  MemCpy(char_bmp_white_space,saved,sizeof(saved));
  if(!MemCmp(char_bmp_white_space,saved,sizeof(saved)))mask|=32;
  Fs->put_doc=put;DocDel(d);Free(value);Free(line);
  Fs->answer=answer;Fs->answer_type=type;Fs->answer_time=elapsed;Fs->new_answer=pending;
  s=MStrPrint("EXPORT whitespace-mask.bin %X 8\n",&mask);WBLog(s);Free(s);
  WBLog("WHITESPACE DONE\n");Sleep(1000);
}
