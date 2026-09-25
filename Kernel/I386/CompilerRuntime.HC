//Disk-loaded lexer/numerical runtime. This image remains owned by the boot kernel.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/CompilerRuntime.HH"
#include "/Compiler/I386/LexString.HH"
#include "/Compiler/I386/LexNumber.HH"
#include "/Compiler/I386/LexChar.HH"
#include "/Compiler/I386/LexPunct.HH"
#include "/Compiler/I386/LexIdent.HH"
#include "/Compiler/I386/Lex.HH"
#include "/Kernel/I386/Cpu.HH"
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import Bool I386LexIncludeCopy(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
import CHash *HashFind(U8 *name,CHashTable *table,I64 mask,I64 instance=1);
import U0 HashAdd(CHash *entry,CHashTable *table);
import I64 StrCmp(U8 *left,U8 *right);
import I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
import I64 I386LexSourceRead(U8 *context,CCmpCtrl *cc);
import U32 char_bmp_hex_numeric[16];
import U32 char_bmp_dec_numeric[16];
import U32 char_bmp_non_eol[16];
import U32 char_bmp_non_eol_white_space[16];
import CLexFile *I386LexFilePush(CI386Heap *heap,CCmpCtrl *cc);
import CLexFile *LexFileReleaseTop(CCmpCtrl *cc,CLexFileRelease *owner);
import CHashTable *I386HashTableNew(CI386Heap *heap,I64 buckets);
import Bool I386HashTableValid(CI386Heap *heap,CHashTable *table);
import Bool I386HashTableDelete(CI386Heap *heap,CHashTable *table);
U32 runtime_first[TK_TKS_NUM],runtime_second[TK_TKS_NUM],runtime_third[TK_TKS_NUM];
CLexPunctTables runtime_punct;
extern I64 I386RuntimePunct(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines);
extern I64 I386RuntimeLexNext(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,I64 *compiled_lines);
extern I64 I386RuntimeLexIncludes(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,I64 *compiled_lines,CI386LexIncludeService *includes);
extern U0 ICInfoInit();
extern U0 I386ExecutionBreakPoll();
extern I64 I386ModulePackRaw(U8 *output,I64 capacity,U8 *code,I64 code_bytes,
  CI386ModuleRecord *records,I64 record_count,U8 *strings,I64 string_bytes);
U32 compiler_runtime_version=I386_COMPILER_SERVICES_VERSION;
extern Bool I386MathBind(CHashTable *symbols);
#assert sizeof(CI386CompilerServices)==220
I64 Main(CI386CompilerServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386CompilerServices)) return 0;
  ICInfoInit;
  LexPunctInit(runtime_first,runtime_second,runtime_third);
  runtime_punct.first=runtime_first; runtime_punct.second=runtime_second; runtime_punct.third=runtime_third;
  services->version=compiler_runtime_version;
  services->bytes=sizeof(CI386CompilerServices);
  services->string_chunk=&I386LexStringChunk;
  services->number_token=&I386LexNumber;
  services->char_token=&I386LexChar;
  services->punct_token=&I386RuntimePunct;
  services->ident_scan=&I386LexIdentScan;
  services->ident_token=&I386LexIdentToken;
  services->string_token=&I386LexStringToken;
  services->next_token=&I386RuntimeLexNext;
  services->next_token_with_includes=&I386RuntimeLexIncludes;
  services->control_new=&I386CmpCtrlNew; services->control_del=&I386CmpCtrlDel;
  services->symbols_init=&I386TaskSymbolsInit;
  services->control_enter=&I386CmpCtrlEnter; services->control_leave=&I386CmpCtrlLeave;
  services->control_drain=&I386CmpCtrlDrain; services->control_unwind=&I386CmpCtrlUnwind;
  services->code_add=&I386ICAdd; services->code_misc=&I386COCMiscNew;
  services->code_discard=&I386COCDiscard; services->code_save=&I386COCSave;
  services->code_push=&I386COCPush; services->code_pop=&I386COCPopNoFree;
  services->code_free=&I386COCHeaderFree; services->code_append=&I386COCAppend;
  services->code_retire=&I386ICRetire; services->code_branch=&I386OptBranch; services->code_optimize=&I386OptPass012;
  services->out_new=&I386OutNew; services->out_del=&I386OutDel;
  services->backend=&I386BackendCompile;
  services->expression=&I386ParseExpression;
  services->parse_type=&I386ParseType;
  services->parser_alloc=&I386ParserAlloc; services->parser_free=&I386ParserFree;
  services->parser_token=&I386ParserToken;
  services->parse_declarations=&I386ParseDeclarations; services->code_init=&I386COCInit;
  services->parse_class=&I386ParseClass; services->parse_fun_join=&I386ParseFunJoin;
  services->publish_classes=&I386PublishClasses;
  services->bootstrap_scalars=&I386BootstrapScalars; services->load_scalar_types=&I386LoadScalarTypes;
  services->scalar_types_check=&I386ScalarTypesCheck;
  services->frontend=&I386FrontendServices; services->statement=&I386FrontendStatement;
  services->command=&I386FrontendCommand; services->publish=&I386FrontendPublish; services->input=&I386CommandInput;
  services->break_poll=&I386ExecutionBreakPoll;
  services->math_bind=&I386MathBind;
  services->code_span=&I386FrontendCodeSpan;
  services->module_pack=&I386ModulePackRaw;
  services->code_relocs=&I386FrontendCodeRelocs;
  services->program_pack=&I386FrontendModulePack;
  return 1;
}
#include "/Compiler/I386/LexString.HC"
#include "/Kernel/I386/ModuleCheck.HC"
#include "/Kernel/I386/ModulePackCore.HC"
#include "/Kernel/I386/SoftF64.HC"
#include "/Kernel/I386/FloatMath.HC"
#include "/Kernel/I386/MathPublic.HC"
#include "/Compiler/I386/LexNumber.HC"
#include "/Compiler/I386/LexChar.HC"
#include "/Compiler/LexPunctInit.HC"
#include "/Compiler/I386/LexPunct.HC"
I64 I386RuntimePunct(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines)
{
  return I386LexPunct(heap,cc,ch,&runtime_punct,compiled_lines);
}
#include "/Compiler/MemberLookup.HC"
#include "/Compiler/I386/LexIdent.HC"
#include "/Compiler/I386/LexDefine.HC"
#include "/Compiler/I386/Lex.HC"
I64 I386RuntimeLexNext(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,I64 *compiled_lines)
{
  return I386LexNext(heap,cc,&runtime_punct,macro_filename,compiled_lines);
}

I64 I386RuntimeLexIncludes(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,
  I64 *compiled_lines,CI386LexIncludeService *includes)
{
  return I386LexNextWithIncludes(heap,cc,&runtime_punct,macro_filename,compiled_lines,includes);
}

#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/Control.HC"

#include "/Compiler/I386/SymbolDelete.HC"
#include "/Kernel/I386/TaskSymbols.HC"

#include "/Compiler/I386/OptBranch.HC"

#include "/Compiler/I386/OptPass012.HC"

#include "/Compiler/I386/NativeEmit.HC"

#include "/Compiler/I386/NativeBackend.HC"

#include "/Compiler/I386/NativeExpression.HC"

#include "/Compiler/I386/NativeType.HC"

#include "/Compiler/I386/ParserMemory.HC"

#include "/Compiler/I386/ParserToken.HC"

#include "/Compiler/I386/NativeDeclaration.HC"

#include "/Compiler/I386/NativeSymbol.HC"

#include "/Compiler/I386/PublishClasses.HC"

#include "/Compiler/I386/Intrinsic.HC"
#include "/Compiler/I386/Frontend.HC"
#include "/Compiler/I386/FrontendResident.HC"
#include "/Compiler/I386/FrontendStatements.HC"
#include "/Compiler/I386/FrontendPublish.HC"
#include "/Compiler/I386/ScalarBootstrap.HC"

#include "/Compiler/I386/CommandInput.HC"
