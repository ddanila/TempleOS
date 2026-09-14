#include "/Compiler/I386/LexFileRead.HH"
#include "/Kernel/I386/Cpu.HH"
Bool I386LexIncludeFile(CI386Heap *heap,CCmpCtrl *cc,
  CFilePathContext *paths,CI386FileVolumes *volumes,U8 *filename)
{
  U8 *extension,*name=0,*source;
  Bool attached;
  if(GetRFlags&0x200 || !heap || !cc || !cc->lex_include_stk || !paths || !volumes ||
      !filename || cc->flags&CCF_PMT || cc->opts&OPTF_ECHO || cc->lex_include_stk->flags&LFSF_DOC) return FALSE;
  extension=I386ExtDft(heap,filename,"HC.Z");
  if(!extension) return FALSE;
  //The compiler stores its first absolute name; FileRead normalizes it again.
  name=I386FileNameAbs(heap,paths,extension);
  I386HeapFree(heap,extension);
  if(!name) return FALSE;
  source=I386FileReadAt(heap,paths,volumes,name);
  if(!source) { I386HeapFree(heap,name); return FALSE; }
  attached=I386LexIncludeTake(heap,cc,name,source,FALSE);
  I386HeapFree(heap,name);
  if(!attached) I386HeapFree(heap,source);
  return attached;
}

Bool I386LexFileInclude(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *filename)
{
  CI386LexFileContext *files=context;
  if(!files) return FALSE;
  return I386LexIncludeFile(heap,cc,files->paths,files->volumes,filename);
}
