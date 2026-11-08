#ifndef I386_PUBLIC_LOADER_INCLUDED
#define I386_PUBLIC_LOADER_INCLUDED
#include "/Kernel/I386/PublicHash.HH"
#include "/Kernel/LoadFlags.HH"
#include "/Kernel/CompilerTypes.HH"
#include "/Kernel/PatchTypes.HH"
#help_index "Loader"
public _extern _LOAD_ONE_IMPORT U0 LoadOneImport(U8 **src,U8 *module_base,I64 flags=0);
public _extern _SYS_SYM_IMPORTS_RESOLVE U0 SysSymImportsResolve(U8 *name,I64 flags=0);
public _extern _CMP_FIX_UP_JIT_ASM U0 CmpFixUpJITAsm(CCmpCtrl *cc,CAOT *aot);
public _extern _CMP_FIX_UP_AOT_ASM U0 CmpFixUpAOTAsm(CCmpCtrl *cc,CAOT *aot);
#endif
