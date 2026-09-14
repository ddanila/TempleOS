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

U0 I386LexIncludePublish(CI386Heap *heap,CCmpCtrl *cc,CI386LexFile *file,
  U8 *owned_name,U8 *owned_source,Bool is_define)
{
  U32 flags;
  file->heap=heap; file->control=cc; file->signature=I386_LEX_FILE_MAGIC;
  file->file.full_name=owned_name;
  file->file.buf=file->file.buf_ptr=file->file.line_start=owned_source;
  file->file.line_num=1;
  if(is_define) file->file.flags=LFSF_DEFINE;
  flags=I386IrqSave;
  LexBackupLastChar(cc);
  LexFileAttach(cc,&file->file);
  cc->cur_buf_ptr=owned_source;
  I386IrqRestore(flags);
}

Bool I386LexIncludeTake(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE)
{
  CI386LexFile *file;
  CLexFile *parent;
  U8 *owned_name=0;
  I64 name_size=1,source_size,i;
  U32 flags;
  if(!cc || !cc->lex_include_stk || !name || !source || cc->flags&CCF_PMT ||
      cc->opts&OPTF_ECHO || cc->lex_include_stk->flags&LFSF_DOC) return FALSE;
  flags=I386IrqSave;
  source_size=I386HeapSize(heap,source);
  I386IrqRestore(flags);
  if(source_size<1 || source[source_size-1]) return FALSE;
  //The source must have one owner; reject buffers already owned by this control.
  if(source==cc->cur_str || source==(cc+0)(U8 *)) return FALSE;
  for(parent=cc->lex_include_stk;parent;parent=parent->next)
    if(source==parent->buf || source==parent->full_name || source==(parent+0)(U8 *)) return FALSE;
  while(name[name_size-1]) name_size++;
  flags=I386IrqSave;
  file=I386HeapAlloc(heap,sizeof(CI386LexFile),TRUE);
  if(file) owned_name=I386HeapAlloc(heap,name_size,FALSE);
  if(!owned_name) {
    if(file) I386HeapFree(heap,file);
    I386IrqRestore(flags); return FALSE;
  }
  I386IrqRestore(flags);
  for(i=0;i<name_size;i++) owned_name[i]=name[i];
  I386LexIncludePublish(heap,cc,file,owned_name,source,is_define);
  return TRUE;
}

Bool I386LexIncludeCopy(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE)
{
  CI386LexFile *file;
  U8 *owned_name=0,*owned_source=0;
  I64 name_size=1,source_size=1,i;
  U32 flags;
  if(!cc || !cc->lex_include_stk || !name || !source || cc->flags&CCF_PMT ||
      cc->opts&OPTF_ECHO || cc->lex_include_stk->flags&LFSF_DOC) return FALSE;
  while(name[name_size-1]) name_size++;
  while(source[source_size-1]) source_size++;
  flags=I386IrqSave;
  file=I386HeapAlloc(heap,sizeof(CI386LexFile),TRUE);
  if(file) owned_name=I386HeapAlloc(heap,name_size,FALSE);
  if(owned_name) owned_source=I386HeapAlloc(heap,source_size,FALSE);
  if(!owned_source) {
    if(owned_name) I386HeapFree(heap,owned_name);
    if(file) I386HeapFree(heap,file);
    I386IrqRestore(flags);
    return FALSE;
  }
  I386IrqRestore(flags);
  //Copy outside the interrupt-masked allocation section. Inputs stay borrowed/live.
  for(i=0;i<name_size;i++) owned_name[i]=name[i];
  for(i=0;i<source_size;i++) owned_source[i]=source[i];
  I386LexIncludePublish(heap,cc,file,owned_name,owned_source,is_define);
  return TRUE;
}
