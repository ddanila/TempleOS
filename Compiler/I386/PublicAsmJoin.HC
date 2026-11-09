#include "/Compiler/CmpAbortPacketCore.HC"
U0 NativeSystemCodeAbort(CCmpCtrl *cc,CCodeCtrl *boundary,Bool clear_base)
{
  (*native_jit_support.abort_code)(cc,boundary,clear_base);
}
#define CMP_JOIN_CODE_ABORT NativeSystemCodeAbort
#include "/Compiler/MapFileWriteCore.HC"
#define CMP_JOIN_IMPL NativeSystemCmpJoin
#include "/Compiler/CmpJoinCore.HC"
#define CMP_JOIN_IMPL CmpJoin
#define CMP_BUF_IMPL NativeSystemCmpBuf
#include "/Compiler/CmpBufCore.HC"
#define CMP_BUF_IMPL CmpBuf
if(native_jit_support.asm_stage!=2)throw('AsmLoad');
native_jit_support.asm_stage=3;
