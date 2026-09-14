I64 file_alloc_frees,file_doc_frees,file_context_errors;
U0 FileTestFree(U8 *context,U8 *allocation)
{
  if(context!=&file_alloc_frees) file_context_errors++;
  if(allocation) { file_alloc_frees++; StateFree(allocation); }
}
U0 FileTestDoc(U8 *context,CDoc *document)
{
  if(context!=&file_alloc_frees) file_context_errors++;
  if(document) { file_doc_frees++; StateFree(document); }
}
I64 LexFilesTest()
{
  CCmpCtrl *cc=StateAlloc(sizeof(CCmpCtrl));
  CLexFileRelease owner;
  CLexFile *root,*child,*grandchild;
  U8 borrowed[8],*root_payload;
  I64 mode,doc,retain,expected_alloc,expected_doc;
  if(!cc) return 20;
  CmpCtrlSeed(cc,0,0,0);
  owner.context=&file_alloc_frees; owner.allocation=&FileTestFree; owner.document=&FileTestDoc;
  file_context_errors=0;
  for(mode=0;mode<4;mode++) {
    doc=mode&1; retain=mode&2;
    cc->flags=0; if(retain) cc->flags=CCF_DONT_FREE_BUF;
    cc->cur_buf_ptr=borrowed;
    file_alloc_frees=0; file_doc_frees=0;
    root=StateAlloc(sizeof(CLexFile)); child=StateAlloc(sizeof(CLexFile)); grandchild=StateAlloc(sizeof(CLexFile));
    if(!root || !child || !grandchild) return 21;
    if(LexFileAttach(cc,root)!=root || root->next || root->depth!=-1 || cc->cur_buf_ptr!=borrowed) return 22;
    root->full_name=StateAlloc(8); root_payload=StateAlloc(32);
    if(doc) { root->flags=LFSF_DOC; root->doc=root_payload; root->buf=borrowed; }
    else root->buf=root_payload;
    if(LexFileAttach(cc,child)!=child || child->next!=root || child->depth!=0) return 23;
    child->full_name=StateAlloc(8);
    if(!doc) { child->flags=LFSF_DOC; child->doc=StateAlloc(32); child->buf=borrowed; }
    else child->buf=StateAlloc(32);
    if(LexFileAttach(cc,grandchild)!=grandchild || grandchild->depth!=1 || grandchild->next!=child) return 24;
    grandchild->flags=LFSF_DOC; grandchild->buf=borrowed; //Null document: never release the borrowed buffer.
    if(LexFileReleaseTop(cc,&owner)!=child || file_alloc_frees!=1 || file_doc_frees) return 25;
    if(LexFileReleaseTop(cc,&owner)!=root || cc->cur_buf_ptr!=borrowed) return 26;
    expected_alloc=3; expected_doc=1;
    if(doc) { expected_alloc=4; expected_doc=0; }
    if(file_alloc_frees!=expected_alloc || file_doc_frees!=expected_doc) return 27;
    if(LexFileReleaseTop(cc,&owner) || cc->lex_include_stk || cc->cur_buf_ptr!=borrowed) return 28;
    expected_alloc+=2;
    if(!retain) { if(doc) expected_doc++; else expected_alloc++; }
    if(file_alloc_frees!=expected_alloc || file_doc_frees!=expected_doc || file_context_errors) return 29;
    if(LexFileReleaseTop(cc,&owner) || file_alloc_frees!=expected_alloc || file_doc_frees!=expected_doc) return 30;
    if(retain) StateFree(root_payload);
  }
  StateFree(cc); return 0;
}
