//Ordered normal shared-parser stage.
#include "/Kernel/SymbolDelete.HC"
#include "/Compiler/PrsMemberDelete.HC"
#include "/Compiler/PrsOptions.HC"
#include "/Compiler/PrsExternDiagnostics.HC"
#include "/Compiler/PrsSymbolHost.HC"

if(native_jit_support.prs_stage!=6)throw('PrsLoad');
native_jit_support.prs_stage=7;
