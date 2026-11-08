//Complete shared assembly services, loaded only on first assembly/join call.
#include "/Kernel/I386/PublicAssembly.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicFiles.HH"
#include "/Compiler/Keywords.HH"
#include "/Compiler/PrsCompileFlags.HH"
#include "/Kernel/CharBitmaps.HH"
#include "/Compiler/LexSkipEolCore.HC"
//The shared assembler uses the ordinary non-atomic I64 swap operation.
U0 SwapI64(I64 *a,I64 *b){I64 value=*a;*a=*b;*b=value;}
#include "/Compiler/AsmExpressionCore.HC"
if(native_jit_support.asm_stage!=0)throw('AsmLoad');
native_jit_support.asm_stage=1;
