U0 LSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 LSCheck()
{
  I64 mask=0,used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s,*result;
  U8 *s,*buffer;CCmpCtrl *cc=CmpCtrlNew(StrNew("abcdef\nz"));
  CLexFile *file=cc->lex_include_stk,*outer,*inner,*parent,*child;
  if(!cc->lex_prs_stk && LexGetChar(cc)=='a')mask|=1;
  LexPush(cc);outer=cc->lex_prs_stk;
  if(outer && outer!=file && !outer->next && MSize(outer)==MSize(file) &&
      outer->buf==file->buf && outer->full_name==file->full_name &&
      outer->buf_ptr==cc->cur_buf_ptr && outer->line_num==file->line_num)mask|=2;
  if(LexGetChar(cc)=='b' && LexGetChar(cc)=='c')mask|=4;
  LexPush(cc);inner=cc->lex_prs_stk;
  if(inner && inner!=outer && inner->next==outer && LexGetChar(cc)=='d')mask|=8;
  LexPopRestore(cc);
  if(cc->lex_prs_stk==outer && LexGetChar(cc)=='d')mask|=16;
  LexPopNoRestore(cc);
  if(!cc->lex_prs_stk && LexGetChar(cc)=='e')mask|=32;
  cc->flags|=CCF_USE_LAST_U16;LexPush(cc);
  if(cc->flags&CCF_USE_LAST_U16 && cc->lex_prs_stk->last_U16=='e' &&
      LexGetChar(cc)=='e' && LexGetChar(cc)=='f') {
    LexPopRestore(cc);
    if(cc->flags&CCF_USE_LAST_U16 && LexGetChar(cc)=='e' && LexGetChar(cc)=='f')mask|=64;
  } else LexPopRestore(cc);
  LexPush(cc);
  if(LexGetChar(cc)=='\n' && LexGetChar(cc)=='z' && file->line_num==2) {
    LexPopRestore(cc);
    if(file->line_num==1 && file->line_start==file->buf &&
        LexGetChar(cc)=='\n' && LexGetChar(cc)=='z')mask|=128;
  } else LexPopRestore(cc);
  cc->token=11;cc->cur_i64=5;LexPush(cc);cc->token=22;cc->cur_i64=9;LexPopRestore(cc);
  if(cc->token==22 && cc->cur_i64==9 && !cc->lex_prs_stk)mask|=256;
  CmpCtrlDel(cc);
  cc=CmpCtrlNew(StrNew("pq"));LexPush(cc);LexPush(cc);CmpCtrlDel(cc);
  if(Fs->data_heap->used_u8s==used && Fs->code_heap->used_u8s==code_used)mask|=512;
  buffer=StrNew("xy");cc=CmpCtrlNew(buffer,CCF_DONT_FREE_BUF);
  LexPush(cc);LexPush(cc);LexPopRestore(cc);CmpCtrlDel(cc);
  if(MSize(buffer)>=3 && !StrCmp(buffer,"xy")) {
    Free(buffer);
    if(Fs->data_heap->used_u8s==used && Fs->code_heap->used_u8s==code_used)mask|=1024;
  } else Free(buffer);
  cc=CmpCtrlNew(StrNew("parent"));parent=cc->lex_include_stk;
  child=CAlloc(sizeof(CLexFile));child->next=parent;child->depth=0;child->line_num=7;
  child->full_name=StrNew("C:/Probe/Child.HC");
  child->buf=child->buf_ptr=child->line_start=StrNew("uv");
  cc->lex_include_stk=child;cc->cur_buf_ptr=child->buf;
  LexGetChar(cc);LexPush(cc);LexGetChar(cc);child->line_num=99;LexPopRestore(cc);
  if(cc->lex_include_stk==child && child->next==parent && child->line_num==7 &&
      LexGetChar(cc)=='v')mask|=2048;
  CmpCtrlDel(cc);
  if(Fs->data_heap->used_u8s!=used || Fs->code_heap->used_u8s!=code_used)mask&=~2048;
  CDoc *doc=DocNew;DocPrint(doc,"ab\nc");
  cc=CmpCtrlNew(StrNew("R"));LexAttachDoc(cc,,doc);file=cc->lex_include_stk;
  if(LexGetChar(cc)=='a') {
    LexPush(cc);
    if(LexGetChar(cc)=='b' && LexGetChar(cc)=='\n' && LexGetChar(cc)=='c') {
      LexPopRestore(cc);
      if(file->flags&LFSF_DOC && file->doc==doc && file->next &&
          LexGetChar(cc)=='b' && LexGetChar(cc)=='\n' && LexGetChar(cc)=='c')mask|=4096;
    } else LexPopRestore(cc);
  }
  CmpCtrlDel(cc);
  if(Fs->data_heap->used_u8s!=used || Fs->code_heap->used_u8s!=code_used)mask&=~4096;
  result=MAlloc(8);*result=mask;
  s=MStrPrint("EXPORT lex-savepoints-mask.bin %X 8\n",result);LSLog(s);Free(s);
  LSLog("LEX SAVEPOINTS DONE\n");Sleep(1000);
}
LSCheck;
