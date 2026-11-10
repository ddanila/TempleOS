//Compile the complete shared optimizer in Adam; canonical types are borrowed.
#include "/Compiler/I386/SystemCompiler.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Compiler/ICInfo.HC"
#include "/Compiler/PrsStack.HC"
#include "/Compiler/TargetSize.HC"
#include "/Compiler/OptCode.HC"
#include "/Compiler/ICDetachCore.HC"
#include "/Compiler/OptFreeCore.HC"
#include "/Compiler/OptTypes.HC"
#include "/Compiler/OptBranch.HC"
#include "/Compiler/OptSize.HC"
#include "/Compiler/ICDiagnosticsCore.HC"
#define OPT_PASS012_IMPL NativeSystemOptPass012
#include "/Compiler/OptPass012.HC"
#define OPT_PASS012_IMPL OptPass012
ICInfoInit;
U0 NativeSystemOptPublish()
{
 U8 *s="PUBLIC OPT loaded\n";
 native_jit_support.optimize=&NativeSystemOptPass012;
 while(*s)OutU8(0xE9,*s++);
}
NativeSystemOptPublish;
