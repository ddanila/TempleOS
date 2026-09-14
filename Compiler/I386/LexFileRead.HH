#ifndef I386_LEX_FILE_READ_INCLUDED
#define I386_LEX_FILE_READ_INCLUDED
#include "/Compiler/I386/LexFiles.HH"
#include "/Kernel/I386/FileContext.HH"
//Add the default HC.Z extension, load decoded source and publish an owned child.
//Quiescent file service, IF clear. Failure preserves active input and reclaims temporaries.
public extern Bool I386LexIncludeFile(CI386Heap *heap,CCmpCtrl *cc,
  CFilePathContext *paths,CI386FileVolumes *volumes,U8 *filename);
#endif
