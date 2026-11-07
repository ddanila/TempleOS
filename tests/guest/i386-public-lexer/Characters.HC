U0 PLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PLCheck()
{
  I64 v[16],used=Fs->data_heap->used_u8s;
  U8 *buffer=CAlloc(6),*s;
  CCmpCtrl *cc;
  CDoc *doc;
  buffer[0]=CH_CURSOR;buffer[1]='A';buffer[2]='\n';
  buffer[3]=CH_SHIFT_SPACE;buffer[4]='B';
  cc=CmpCtrlNew(buffer);
  v[0]=LexGetChar(cc)=='A' && cc->cur_buf_ptr==buffer+2;
  v[1]=LexGetChar(cc)=='\n' && cc->lex_include_stk->line_num==2 &&
    cc->lex_include_stk->line_start==buffer+3;
  cc->flags|=CCF_USE_LAST_U16;
  v[2]=LexGetChar(cc)=='\n' && cc->cur_buf_ptr==buffer+3 &&
    cc->lex_include_stk->line_num==2 && !(cc->flags&CCF_USE_LAST_U16);
  v[3]=LexGetChar(cc)==CH_SPACE && LexGetChar(cc)=='B';
  v[4]=LexGetChar(cc)==TK_EOF && LexGetChar(cc)==TK_EOF;
  CmpCtrlDel(cc);v[5]=Fs->data_heap->used_u8s==used;
  buffer=StrNew("R");cc=CmpCtrlNew(buffer,CCF_DONT_FREE_BUF);
  v[6]=LexGetChar(cc)=='R';cc->flags|=CCF_USE_LAST_U16;
  doc=DocNew("CharacterInclude.HC");DocPrint(doc,"I");
  LexAttachDoc(cc,,doc);
  v[7]=cc->lex_include_stk->next &&
    cc->lex_include_stk->doc==doc &&
    !StrCmp(cc->lex_include_stk->full_name,doc->filename.name) &&
    cc->lex_include_stk->line_num==1 && LexGetChar(cc)=='I';
  v[8]=LexGetChar(cc)=='R' && !cc->lex_include_stk->next &&
    cc->cur_buf_ptr==buffer+1 && LexGetChar(cc)==TK_EOF;
  CmpCtrlDel(cc);v[9]=MSize(buffer)>=2 && !StrCmp(buffer,"R");Free(buffer);
  v[10]=Fs->data_heap->used_u8s==used;
  doc=DocNew("CharacterInput.HC");DocPrint(doc,"alpha\n\tbeta");
  cc=CmpCtrlNew();LexAttachDoc(cc,,doc);
  v[11]=cc->lex_include_stk->doc==doc &&
    cc->lex_include_stk->flags&LFSF_DOC;
  v[12]=LexGetChar(cc)=='a' && LexGetChar(cc)=='l' &&
    LexGetChar(cc)=='p' && LexGetChar(cc)=='h' && LexGetChar(cc)=='a';
  v[13]=LexGetChar(cc)=='\n' && LexGetChar(cc)=='\t' &&
    LexGetChar(cc)=='b' && LexGetChar(cc)=='e' &&
    LexGetChar(cc)=='t' && LexGetChar(cc)=='a';
  v[14]=LexGetChar(cc)==TK_EOF && !cc->lex_include_stk->next;
  CmpCtrlDel(cc);v[15]=Fs->data_heap->used_u8s==used;
  s=MStrPrint("EXPORT public-lexer.bin %X %X\n",v,sizeof(v));PLLog(s);Free(s);
  PLLog("PUBLIC LEXER DONE\n");Sleep(1000);
}
