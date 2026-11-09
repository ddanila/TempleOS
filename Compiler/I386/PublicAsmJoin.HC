#include "/Compiler/MapFileWriteCore.HC"
#define CMP_JOIN_IMPL NativeSystemCmpJoin
#include "/Compiler/CmpJoinCore.HC"
#define CMP_JOIN_IMPL CmpJoin
#define CMP_BUF_IMPL NativeSystemCmpBuf
#include "/Compiler/CmpBufCore.HC"
#define CMP_BUF_IMPL CmpBuf
if(native_jit_support.asm_stage!=2)throw('AsmLoad');
native_jit_support.asm_stage=3;
