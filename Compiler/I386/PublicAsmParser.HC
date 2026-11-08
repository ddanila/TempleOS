#define PRS_ASM_BLOCK_IMPL NativeSystemPrsAsmBlk
#include "/Compiler/Asm.HC"
#define PRS_ASM_BLOCK_IMPL PrsAsmBlk
if(native_jit_support.asm_stage!=1)throw('AsmLoad');
native_jit_support.asm_stage=2;
