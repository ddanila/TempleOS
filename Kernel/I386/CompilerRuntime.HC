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
U32 compiler_runtime_version=I386_COMPILER_SERVICES_VERSION;
#assert sizeof(CI386CompilerServices)==72
I64 Main(CI386CompilerServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386CompilerServices)) return 0;
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
  return 1;
}
#include "/Compiler/I386/LexString.HC"
#include "/Kernel/I386/SoftF64.HC"
#include "/Kernel/I386/Pow10.HC"
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
