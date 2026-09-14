I64 native_doc_releases,native_doc_errors;
U0 NativeFileDocRelease(U8 *context,CDoc *document)
{
  if(context!=&native_doc_releases) native_doc_errors++;
  native_doc_releases++; StateFree(document);
}
I64 NativeFilesTest()
{
  CCmpCtrl cc,other;
  CI386Heap small,foreign;
  CLexFile *root,*child;
  U8 *bytes,*payload;
  I64 i,size,used;
  U32 flags=I386IrqSave;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&other; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,0,0);
  if(I386LexFilePush(0,&cc) || I386LexFilePush(&state_heap,0) ||
      I386LexFilePop(&state_heap,&cc) || I386LexFilePop(&state_heap,0)) return 31;
  for(size=24;size<80;size+=8) {
    if(!I386HeapInit(&small,0x61000,size) || I386LexFilePush(&small,&cc) ||
        small.used || small.allocations || cc.lex_include_stk) return 32;
  }
  if(!I386HeapInit(&small,0x61000,80) || !I386LexFilePush(&small,&cc) ||
      !I386LexFilePop(&small,&cc) || small.used || small.allocations || cc.lex_include_stk) return 45;
  SetRFlags(GetRFlags|0x200);
  root=I386LexFilePush(&state_heap,&cc);
  if(!root || root->depth!=-1 || root->next || root->buf || root->doc || root->flags ||
      root->full_name || root->last_U16 || !(GetRFlags&0x200)) return 33;
  payload=StateAlloc(32); root->buf=payload; root->full_name=StateAlloc(8);
  child=I386LexFilePush(&state_heap,&cc);
  if(!child || child->depth!=0 || child->next!=root) return 34;
  child->flags=LFSF_DOC; child->doc=StateAlloc(32); child->full_name=StateAlloc(8);
  used=state_heap.used;
  if(!I386HeapInit(&foreign,0x62000,512)) return 35;
  other.lex_include_stk=child;
  if(I386LexFilePop(&foreign,&cc,&NativeFileDocRelease,&native_doc_releases) ||
      I386LexFilePop(&state_heap,&other,&NativeFileDocRelease,&native_doc_releases) ||
      I386LexFilePop(&state_heap,&cc) || cc.lex_include_stk!=child || state_heap.used!=used || !(GetRFlags&0x200)) return 36;
  other.lex_include_stk=0;
  if(!I386LexPush(&state_heap,&cc)) return 37;
  if(I386LexFilePop(&state_heap,&cc,&NativeFileDocRelease,&native_doc_releases) ||
      cc.lex_include_stk!=child || !cc.lex_prs_stk) return 38;
  if(!I386LexPop(&state_heap,&cc,FALSE) ||
      !I386LexFilePop(&state_heap,&cc,&NativeFileDocRelease,&native_doc_releases) ||
      native_doc_releases!=1 || native_doc_errors || cc.lex_include_stk!=root || !(GetRFlags&0x200)) return 39;
  if(!I386LexFilePop(&state_heap,&cc) || cc.lex_include_stk || state_heap.allocations!=1 ||
      I386HeapSize(&state_heap,payload)!=32 || !(GetRFlags&0x200)) return 40;
  StateFree(payload);
  //A retained root document requires no release service; the caller retains it.
  root=I386LexFilePush(&state_heap,&cc); if(!root) return 41;
  payload=StateAlloc(32); root->flags=LFSF_DOC; root->doc=payload;
  if(!I386LexFilePop(&state_heap,&cc) || native_doc_releases!=1 || state_heap.allocations!=1) return 42;
  StateFree(payload);
  I386IrqSave;
  cc.flags=0; root=I386LexFilePush(&state_heap,&cc);
  if(!root) return 43;
  root->buf=StateAlloc(32);
  if(!I386LexFilePop(&state_heap,&cc) || GetRFlags&0x200 || state_free_errors ||
      state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap)) return 44;
  I386IrqRestore(flags); return 0;
}
