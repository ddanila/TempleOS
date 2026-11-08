#ifndef I386_PUBLIC_COMPILER_INCLUDED
#define I386_PUBLIC_COMPILER_INCLUDED
#include "/Kernel/I386/PublicDocument.HH"
#include "/Kernel/I386/PublicLoader.HH"
#include "/Compiler/CompilerA.HH"
public _extern _OPT_PASS012 CIntermediateCode *OptPass012(CCmpCtrl *cc);
public _extern _COC_COMPILE U8 *COCCompile(CCmpCtrl *cc,I64 *_code_size,CDbgInfo **_dbg,I64 *_type);
#endif
