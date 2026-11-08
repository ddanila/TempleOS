//Ordered normal shared-parser stage.
#include "/Kernel/SymbolDelete.HC"
#include "/Compiler/PrsMemberDelete.HC"
#include "/Compiler/PrsDeclarationHost.HC"

if(native_jit_support.prs_stage!=5)throw('PrsLoad');
native_jit_support.prs_stage=6;
