#ifndef COMPILER_LEX_FILES_INCLUDED
#define COMPILER_LEX_FILES_INCLUDED
#include "/Kernel/CompilerTypes.HH"
public class CLexFileRelease
{
  U8 *context;
  U0 (*allocation)(U8 *context,U8 *allocation);
  U0 (*document)(U8 *context,CDoc *document);
};
public extern CLexFile *LexFileAttach(CCmpCtrl *cc,CLexFile *file);
public extern CLexFile *LexFileReleaseTop(CCmpCtrl *cc,CLexFileRelease *owner);
#endif
