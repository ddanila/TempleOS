#ifndef I386_LEX_FILES_KNOWN_INCLUDED
#define I386_LEX_FILES_KNOWN_INCLUDED
#include "/Compiler/I386/LexFiles.HH"
#include "/Kernel/I386/HeapKnown.HC"
Bool I386LexFileOwnedKnown(CI386Heap *heap,CCmpCtrl *cc,CLexFile *file)
{//The caller has validated the unchanged heap under IRQ exclusion.
  CI386LexFile *owned=file;
  return I386HeapKnownSize(heap,file,sizeof(CI386LexFile)) &&
    owned->signature==I386_LEX_FILE_MAGIC && owned->heap==heap && owned->control==cc;
}
#endif
