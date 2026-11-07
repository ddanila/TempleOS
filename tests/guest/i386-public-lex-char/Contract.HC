U0 LCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 LCCheck()
{
  CHash *h=HashFind("LexGetChar",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
  I64 (*read_char)(CCmpCtrl *cc);
  CCmpCtrl *cc=NULL;CDoc *d=NULL,*source;
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  I64 chars[26],state[8],i,n=0;
  I64 answer=Fs->answer,type=Fs->answer_type;
  F64 elapsed=Fs->answer_time;Bool pending=Fs->new_answer;
  U8 *buf,*s;
  if(!h){LCLog("PUBLIC LEX CHAR UNAVAILABLE\n");return;}
  if(h->type&HTT_FUN)read_char=h(CHashFun *)->exe_addr;
  else read_char=h(CHashExport *)->val;
  if(!read_char){LCLog("PUBLIC LEX CHAR UNAVAILABLE\n");return;}
  try {
    buf=CAlloc(6);buf[0]='A';buf[1]=CH_CURSOR;buf[2]=CH_SHIFT_SPACE;buf[3]='\n';buf[4]='B';
    cc=CmpCtrlNew(buf);
    chars[n++]=(*read_char)(cc);Bts(&cc->flags,CCf_USE_LAST_U16);
    for(i=0;i<6;i++)chars[n++]=(*read_char)(cc);
    state[0]=cc->lex_include_stk->line_num;
    state[1]=!Bt(&cc->flags,CCf_USE_LAST_U16);
    CmpCtrlDel(cc);cc=NULL;
    cc=CmpCtrlNew(StrNew("R"));source=DocNew;DocPrint(source,"xy\nz");
    LexAttachDoc(cc,,source);
    for(i=0;i<7;i++)chars[n++]=(*read_char)(cc);
    state[2]=cc->lex_include_stk->next==NULL;
    CmpCtrlDel(cc);cc=NULL;
    d=DocNew;Fs->put_doc=d;Fs->new_answer=FALSE;
    cc=CmpCtrlNew(,CCF_PMT|CCF_QUESTION_HELP);
    In("\n?\n?\n");
    for(i=0;i<10;i++)chars[n++]=(*read_char)(cc);
    state[3]=cc->pmt_line;state[4]=cc->lex_include_stk->line_num;
    CmpCtrlDel(cc);cc=NULL;
    cc=CmpCtrlNew(,CCF_PMT);In("?\n");
    for(i=0;i<2;i++)chars[n++]=(*read_char)(cc);
    state[5]=cc->pmt_line;
    state[6]=DocPut==d && DocDisplay==display && DocBorder==border;
    state[7]=!Bt(&Fs->task_flags,TASKf_CMD_LINE_PMT);
    CmpCtrlDel(cc);cc=NULL;
  } catch {
    if(cc)CmpCtrlDel(cc);Fs->put_doc=put;if(d)DocDel(d);
    Fs->answer=answer;Fs->answer_type=type;Fs->answer_time=elapsed;Fs->new_answer=pending;
  }
  Fs->put_doc=put;DocDel(d);
  Fs->answer=answer;Fs->answer_type=type;Fs->answer_time=elapsed;Fs->new_answer=pending;
  s=MStrPrint("EXPORT lex-char-values.bin %X %X\n",chars,sizeof(chars));LCLog(s);Free(s);
  s=MStrPrint("EXPORT lex-char-state.bin %X %X\n",state,sizeof(state));LCLog(s);Free(s);
  LCLog("PUBLIC LEX CHAR DONE\n");Sleep(1000);
}
