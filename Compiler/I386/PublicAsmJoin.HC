#include "/Compiler/MapFileWriteCore.HC"
#define CMP_JOIN_IMPL NativeSystemCmpJoin
#include "/Compiler/CmpJoinCore.HC"
#define CMP_JOIN_IMPL CmpJoin
if(native_jit_support.asm_stage!=2)throw('AsmLoad');
native_jit_support.asm_stage=3;
