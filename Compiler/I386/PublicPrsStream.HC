//Ordered normal shared-parser stage.
#include "/Kernel/BlkDev/DirFileCore.HC"
#include "/Compiler/PrsStreamOutput.HC"

if(native_jit_support.prs_stage!=10)throw('PrsLoad');
native_jit_support.prs_stage=11;
