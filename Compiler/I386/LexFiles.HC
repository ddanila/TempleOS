#include "/Compiler/I386/LexFiles.HH"
#include "/Compiler/LexFiles.HC"
#include "/Kernel/I386/Cpu.HH"
#define I386_LEX_FILE_MAGIC 0x4C464931
class CI386LexFile
{
  CLexFile file;
  CI386Heap *heap;
  CCmpCtrl *control;
  U32 signature;
};
class CI386LexFileRelease
{
  CI386Heap *heap;
  Bool ok;
};
U0 I386LexFileFree(U8 *context,U8 *allocation)
{
  CI386LexFileRelease *state=context;
  U32 flags=I386IrqSave;
  if(allocation && !I386HeapFree(state->heap,allocation)) state->ok=FALSE;
  I386IrqRestore(flags);
}
CLexFile *I386LexFilePush(CI386Heap *heap,CCmpCtrl *cc)
{
  CI386LexFile *file;
  U32 flags;
  if(!cc) return 0;
  flags=I386IrqSave;
  file=I386HeapAlloc(heap,sizeof(CI386LexFile),TRUE);
  I386IrqRestore(flags);
  if(!file) return 0;
  file->heap=heap; file->control=cc; file->signature=I386_LEX_FILE_MAGIC;
  return LexFileAttach(cc,&file->file);
}
//Keep the caller's document context distinct from the allocator context.
class CI386LexFileDispatch
{
  CI386LexFileRelease release;
  U0 (*document)(U8 *context,CDoc *document);
  U8 *context;
};
U0 I386LexFileDocDel(U8 *context,CDoc *document)
{
  CI386LexFileDispatch *dispatch=context;
  (*dispatch->document)(dispatch->context,document);
}
Bool I386LexFilePop(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document)=0,U8 *context=0)
{
  CI386LexFile *file;
  CLexFileRelease owner;
  CI386LexFileDispatch dispatch;
  U32 flags=I386IrqSave;
  Bool valid=FALSE;
  if(!cc || cc->lex_prs_stk || !(file=cc->lex_include_stk) ||
      I386HeapSize(heap,file)!=sizeof(CI386LexFile)) goto checked;
  if(file->signature!=I386_LEX_FILE_MAGIC || file->heap!=heap || file->control!=cc) goto checked;
  if((file->file.next || !(cc->flags&CCF_DONT_FREE_BUF)) &&
      file->file.flags&LFSF_DOC && file->file.doc && !document) goto checked;
  valid=TRUE;
checked:
  I386IrqRestore(flags);
  if(!valid) return FALSE;
  //Exclusive control/file ownership remains required across document callbacks.
  dispatch.release.heap=heap; dispatch.release.ok=TRUE;
  dispatch.document=document; dispatch.context=context;
  owner.context=&dispatch; owner.allocation=&I386LexFileFree; owner.document=&I386LexFileDocDel;
  file->signature=0;
  LexFileReleaseTop(cc,&owner);
  return dispatch.release.ok;
}
