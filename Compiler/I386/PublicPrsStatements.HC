//Ordered normal shared-parser stage.
#define PRS_STREAM_BLK_IMPL NativeSystemPrsStreamBlk
#include "/Compiler/PrsStatementHost.HC"
#define PRS_STREAM_BLK_IMPL PrsStreamBlk

if(native_jit_support.prs_stage!=7)throw('PrsLoad');
native_jit_support.prs_stage=8;
