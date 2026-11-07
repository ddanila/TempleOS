U0 PLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PLCheck()
{
  I64 v[12],used=Fs->data_heap->used_u8s,doc_size;
  U8 *buffer=StrNew("root"),*s;
  CCmpCtrl *cc=CmpCtrlNew(buffer);
  CLexFile *root=cc->lex_include_stk;
  CDoc *doc=DocNew("Attachment.HC");
  CDocEntry *entry;
  DocPrint(doc,"alpha");entry=doc->head.next;
  while(entry!=doc && entry->type_u8!=DOCT_TEXT)entry=entry->next;
  if(entry==doc)throw('Fixture');
  entry->min_col=0;entry->max_col=5;entry->y=7;
  cc->cur_buf_ptr=buffer+2;cc->last_U16='o';cc->flags|=CCF_USE_LAST_U16;
  LexAttachDoc(cc,,doc,,entry,2);
  v[0]=cc->lex_include_stk->next==root && cc->lex_include_stk->doc==doc &&
    cc->lex_include_stk->flags==LFSF_DOC;
  v[1]=cc->cur_buf_ptr==entry->tag+2 && cc->lex_include_stk->buf_ptr==entry->tag &&
    cc->lex_include_stk->cur_entry==entry && cc->lex_include_stk->line_num==8;
  v[2]=root->buf_ptr==buffer+2 && root->last_U16=='o' && !(cc->flags&CCF_USE_LAST_U16);
  v[3]=cc->lex_include_stk->full_name!=doc->filename.name &&
    !StrCmp(cc->lex_include_stk->full_name,doc->filename.name);
  CmpCtrlDel(cc);v[4]=Fs->data_heap->used_u8s==used;
  doc=DocNew("BorrowedAttachment.HC");DocPrint(doc,"alpha");
  entry=doc->head.next;
  while(entry!=doc && entry->type_u8!=DOCT_TEXT)entry=entry->next;
  if(entry==doc)throw('Fixture');
  entry->min_col=0;entry->max_col=5;entry->y=0;doc_size=DocSize(doc);
  cc=CmpCtrlNew(,CCF_DONT_FREE_BUF);root=cc->lex_include_stk;
  Free(root->full_name);root->full_name=NULL;
  LexAttachDoc(cc,root,doc,,entry,99);
  v[5]=cc->lex_include_stk==root && !root->next && root->doc==doc;
  v[6]=cc->cur_buf_ptr==entry->tag+5;
  CmpCtrlDel(cc);v[7]=doc->doc_signature==DOC_SIGNATURE_VAL && DocSize(doc)==doc_size;
  DocDel(doc);v[8]=Fs->data_heap->used_u8s==used;
  cc=CmpCtrlNew();LexAttachDoc(cc,,,"::/PublicLexerNotes.HC");
  v[9]=cc->lex_include_stk->flags==LFSF_DOC &&
    cc->lex_include_stk->doc->flags&DOCF_DBL_DOLLARS;
  CmpCtrlDel(cc);v[10]=Fs->data_heap->used_u8s==used;
  doc=DocNew("EmptyAttachment.HC");cc=CmpCtrlNew();LexAttachDoc(cc,,doc);
  v[11]=!cc->lex_include_stk->flags && cc->lex_include_stk->line_num==1 &&
    cc->cur_buf_ptr==cc->lex_include_stk->buf && cc->cur_buf_ptr && !cc->cur_buf_ptr[0];
  //Original empty-document attachment keeps a plain empty buffer; caller owns doc.
  CmpCtrlDel(cc);DocDel(doc);v[11]=v[11] && Fs->data_heap->used_u8s==used;
  s=MStrPrint("EXPORT public-lexer.bin %X %X\n",v,sizeof(v));PLLog(s);Free(s);
  PLLog("PUBLIC LEXER DONE\n");Sleep(1000);
}
