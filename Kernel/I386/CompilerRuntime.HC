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
#include "/Kernel/I386/Cpu.HH"
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import Bool I386LexIncludeCopy(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
import CHash *HashFind(U8 *name,CHashTable *table,I64 mask,I64 instance=1);
import I64 StrCmp(U8 *left,U8 *right);
import I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
import I64 I386LexSourceRead(U8 *context,CCmpCtrl *cc);
import U32 char_bmp_hex_numeric[16];
import U32 char_bmp_dec_numeric[16];
import U32 char_bmp_non_eol[16];
U32 runtime_first[TK_TKS_NUM],runtime_second[TK_TKS_NUM],runtime_third[TK_TKS_NUM];
CLexPunctTables runtime_punct;
extern I64 I386RuntimePunct(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines);
U32 compiler_runtime_version=I386_COMPILER_SERVICES_VERSION;
#assert sizeof(CI386CompilerServices)==36
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
