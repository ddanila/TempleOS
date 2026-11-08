//Ordered normal shared-parser stage.
#include "/Kernel/I386/PublicCompiler.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicLexer.HH"
#include "/Kernel/I386/PublicMath.HH"
#include "/Kernel/I386/PublicFiles.HH"
#include "/Kernel/StringLimits.HH"
#include "/Compiler/Keywords.HH"
#include "/Kernel/CharBitmaps.HH"
#include "/Compiler/PrsCompileFlags.HH"
public extern CHashClass *PrsType(CCmpCtrl *cc,CHashClass **first,I64 *mode,CMemberLst *member,U8 **ident,CHashFun **fun,CHashExport **export_entry,CArrayDim *dim,I64 flags);
public extern CHashClass *PrsClass(CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern);
public extern CHashFun *PrsFunJoin(CCmpCtrl *cc,CHashClass *type,U8 *name,I64 flags);
public extern U0 PrsStaticInit(CCmpCtrl *cc,CMemberLst *member,I64 pass);
public extern Bool PrsStmt(CCmpCtrl *cc,I64 try_count=0,CCodeMisc *break_label=NULL,I64 flags=CMPF_PRS_SEMICOLON);
public extern I64 Un(U8 *rip,I64 count=0x80,I64 seg_size=64);
#include "/Kernel/I386/PublicAssembly.HH"
public extern I64 ExeCmdLine(CCmpCtrl *cc);
#include "/Compiler/MemberClassBaseFind.HC"
#include "/Compiler/PrsKeyword.HC"
#include "/Compiler/PrsParenWarning.HC"

if(native_jit_support.prs_stage!=0)throw('PrsLoad');
native_jit_support.prs_stage=1;
