#ifndef I386_LEX_FILES_INCLUDED
#define I386_LEX_FILES_INCLUDED
#include "/Compiler/LexFiles.HH"
#include "/Kernel/I386/Heap.HH"
//Private allocation wrapper; shared with compiler-control cleanup.
class CI386LexFile
{
  CLexFile file;
  CI386Heap *heap;
  CCmpCtrl *control;
  U32 signature;
  U0 (*document)(U8 *context,CDoc *document);
  U8 *document_context;
};
//Copy borrowed name/source into an owned child. Allocation failure leaves input state unchanged.
public extern Bool I386LexIncludeCopy(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
//Transfer a distinct owned, NUL-terminated source allocation on success only.
//Name is borrowed and copied. Failure leaves source ownership and input state unchanged.
public extern Bool I386LexIncludeTake(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
public extern CLexFile *I386LexFilePush(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386LexFileOwned(CI386Heap *heap,CCmpCtrl *cc,CLexFile *file);
public extern Bool I386LexFileAdvance(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386LexFileReleaseDetached(CI386Heap *heap,CCmpCtrl *cc,CLexFile *file);
//Borrow the caller-locked document as the root source; no ownership transfer.
public extern Bool I386LexAttachDocRoot(CI386Heap *heap,CCmpCtrl *cc,CDoc *doc);
//Transfer a distinct child document on success. The destructor must return
//normally, work with interrupts masked, and remain valid until all snapshots
//release the child. Compiler-control teardown must supply equivalent cleanup.
public extern Bool I386LexIncludeDocTake(CI386Heap *heap,CCmpCtrl *cc,U8 *name,CDoc *doc,
  U0 (*document)(U8 *context,CDoc *document),U8 *context=0);
//File/name and owned raw buffers belong to heap; document lifetime uses the callback.
//Drain saved positions before popping. Caller must update its current buffer pointer.
public extern Bool I386LexFilePop(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document)=0,U8 *context=0);
#endif
