I64 NativeInputTest()
{
  CCmpCtrl *cc=StateAlloc(sizeof(CCmpCtrl));
  CLexFile *root,*child;
  U8 *buffer=StateAlloc(8),*saved;
  I64 lines=0,i;
  if(!cc || !buffer) return 66;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF,0,0);
  if(I386LexRawChar(&state_heap,0,&lines)!=-1 || InputRead(cc,&lines)!=-1) return 67;
  root=InputPush(cc); if(!root) return 68;
  buffer[0]='x'; LexFileSeed(root,buffer); cc->cur_buf_ptr=buffer;
  if(I386LexRawChar(&state_heap,cc,0)!=-1) return 69;
  for(i=0;i<3;i++) {
    if(i==0) cc->flags|=CCF_PMT;
    if(i==1) cc->opts|=OPTF_ECHO;
    if(i==2) root->flags|=LFSF_DOC;
    if(InputRead(cc,&lines)!=-1 || cc->cur_buf_ptr!=buffer || lines) return 70;
    cc->flags=CCF_DONT_FREE_BUF; cc->opts=0; root->flags=0;
  }
  child=InputPush(cc); if(!child) return 71;
  LexFileSeed(child,StateAlloc(8)); cc->cur_buf_ptr=child->buf;
  if(!I386LexPush(&state_heap,cc)) return 72;
  saved=cc->cur_buf_ptr;
  if(InputRead(cc,&lines)!='x' || cc->lex_include_stk!=root) return 73;
  if(!I386LexPop(&state_heap,cc) || cc->lex_include_stk!=child ||
      cc->cur_buf_ptr!=saved) return 74;
  root->flags=LFSF_DOC;
  if(InputRead(cc,&lines)!=-1 || cc->lex_include_stk!=child || cc->cur_buf_ptr!=saved) return 75;
  root->flags=0;
  if(InputRead(cc,&lines)!='x' || cc->lex_include_stk!=root || InputRead(cc,&lines)) return 76;
  if(!InputPop(cc)) return 77;
  StateFree(buffer); StateFree(cc);
  if(state_free_errors || state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap)) return 78;
  return 0;
}

I64 doc_child_releases,doc_child_errors;
U0 NativeDocChildRelease(U8 *context,CDoc *doc)
{
  CDocEntry *entry=doc->head.next;
  if(context!=&doc_child_releases || !entry || entry->next!=doc)doc_child_errors++;
  doc_child_releases++;StateFree(entry);StateFree(doc);
}
I64 NativeDocChildTest()
{
  CCmpCtrl *cc=StateAlloc(sizeof(CCmpCtrl));
  CLexFile *root;CDoc *doc;CDocEntry *entry;
  CI386Heap foreign;
  U8 *buffer=StateAlloc(8);I64 lines=0,mode,before;
  if(!cc || !buffer)return 80;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF,0,0);
  root=InputPush(cc);if(!root)return 81;
  if(!I386HeapInit(&foreign,0x62000,512))return 98;
  buffer[0]='p';buffer[1]=0;LexFileSeed(root,buffer);
  for(mode=0;mode<3;mode++) {
    before=doc_child_releases;
    cc->cur_buf_ptr=buffer;root->buf_ptr=buffer;root->last_U16=0;cc->flags&=~CCF_USE_LAST_U16;
    doc=StateAlloc(sizeof(CDoc));entry=StateAlloc(sizeof(CDocEntry));
    if(!doc || !entry)return 82;
    doc->doc_signature=DOC_SIGNATURE_VAL;
    if(I386LexIncludeDocTake(&state_heap,cc,"bad.HC",doc,&NativeDocChildRelease,&doc_child_releases))return 97;
    doc->head.next=entry;entry->next=doc;
    entry->type=DOCT_TEXT;entry->tag="d";
    if(I386LexIncludeDocTake(&foreign,cc,"wrong.HC",doc,
        &NativeDocChildRelease,&doc_child_releases) || foreign.used || foreign.allocations)return 99;
    if(I386LexIncludeDocTake(&state_heap,cc,"test.HC",doc,0) ||
        !I386LexIncludeDocTake(&state_heap,cc,"test.HC",doc,&NativeDocChildRelease,&doc_child_releases))return 83;
    if(I386LexIncludeDocTake(&state_heap,cc,"same.HC",doc,&NativeDocChildRelease,&doc_child_releases))return 84;
    if(mode && !I386LexPush(&state_heap,cc))return 85;
    if(InputRead(cc,&lines)!='d' || InputRead(cc,&lines)!='p' || cc->lex_include_stk!=root)return 86;
    if(doc_child_releases!=before+!mode)return 87;
    if(mode && I386LexIncludeDocTake(&state_heap,cc,"pinned.HC",doc,
        &NativeDocChildRelease,&doc_child_releases))return 96;
    if(mode && !I386LexPop(&state_heap,cc,mode==2))return 88;
    if(mode==2 && (InputRead(cc,&lines)!='d' || InputRead(cc,&lines)!='p' ||
        cc->lex_include_stk!=root))return 92;
    if(doc_child_releases!=before+1)return 93;
    if(InputRead(cc,&lines)!=TK_EOF || doc_child_errors)return 89;
  }
  doc=StateAlloc(sizeof(CDoc));entry=StateAlloc(sizeof(CDocEntry));
  if(!doc || !entry)return 94;
  doc->doc_signature=DOC_SIGNATURE_VAL;doc->head.next=entry;entry->next=doc;
  if(!I386LexIncludeDocTake(&state_heap,cc,"owner.HC",doc,&NativeDocChildRelease,&doc_child_releases) ||
      !I386LexFilePop(&state_heap,cc,&NativeFileDocRelease,&native_doc_releases) ||
      doc_child_releases!=4 || native_doc_releases!=1 || doc_child_errors)return 95;
  if(!InputPop(cc))return 90;
  StateFree(buffer);StateFree(cc);
  if(state_free_errors || state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap))return 91;
  return 0;
}
