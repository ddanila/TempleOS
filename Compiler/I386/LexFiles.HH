#ifndef I386_LEX_FILES_INCLUDED
#define I386_LEX_FILES_INCLUDED
#include "/Compiler/LexFiles.HH"
#include "/Kernel/I386/Heap.HH"
public extern CLexFile *I386LexFilePush(CI386Heap *heap,CCmpCtrl *cc);
//File/name and owned raw buffers belong to heap; document lifetime uses the callback.
//Drain saved positions before popping. Caller must update its current buffer pointer.
public extern Bool I386LexFilePop(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document)=0,U8 *context=0);
#endif
