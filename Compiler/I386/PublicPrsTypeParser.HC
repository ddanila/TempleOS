//Ordered normal shared-parser stage.
#include "/Compiler/PrsMemberBuild.HC"
#include "/Compiler/PrsTypeHost.HC"

if(native_jit_support.prs_stage!=4)throw('PrsLoad');
native_jit_support.prs_stage=5;
