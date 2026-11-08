//The resident shared emitter is stateless: public callbacks own its workspace.
#include "/Kernel/I386/PublicCompiler.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Compiler/I386/Backend.HH"
public _extern _I386_BACKEND_CORE U0 PCBEmit(CI386Backend *backend,I64 bytes);
public extern U64 I386F64Abs(U64 value);
public extern U64 I386F64Sqrt(U64 value);
public extern U64 I386F64Add(U64 a,U64 b);
public extern U64 I386F64Sub(U64 a,U64 b);
public extern U64 I386F64Mul(U64 a,U64 b);
public extern U64 I386F64Div(U64 a,U64 b);
public extern U64 I386F64Mod(U64 a,U64 b);
public extern U64 I386F64FromI64(I64 value);
public extern I64 I386F64ToI64(U64 value);
public extern I64 I386F64Compare(U64 a,U64 b);
public extern I64 Un(U8 *code,I64 bytes,I64 bits);
#include "/Compiler/I386/Emit.HC"
#include "/Compiler/CodeLabel.HC"
#include "/Compiler/I386/ValueClassCore.HC"
#include "/Compiler/I386/CompileFrame.HC"
#include "/Compiler/I386/AsmCore.HC"
#include "/Compiler/I386/AsmReleaseCore.HC"
#include "/Compiler/I386/PublicBackendCore.HC"
U0 NativeSystemBackendPublish()
{
 U8 *s="PUBLIC BACKEND loaded\n";
 native_jit_support.compile=&NativeSystemCOCCompile;
 while(*s)OutU8(0xE9,*s++);
}
NativeSystemBackendPublish;
