//Synchronous compiler diagnostics, retained only between boot and task probes.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/CompilerProbe.HH"
#include "/Compiler/ControlInit.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Hash.HH"
#include "/Kernel/I386/String.HH"
import U0 KernelLog(U8 *text);
import U0 KernelHex(U64 value);
import U0 KernelStop();
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import Bool I386HeapValid(CI386Heap *heap);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
import Bool I386LexIncludeCopy(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
import U0 HashAdd(CHash *entry,CHashTable *table);
import I64 StrCmp(U8 *left,U8 *right);
import U32 char_bmp_alpha_numeric[16];
extern U0 ProbeTokens(CI386CompilerProbe *probe);
extern U0 ProbeIdent(CI386CompilerProbe *probe);
extern U0 ProbeDefine(CI386CompilerProbe *probe);
U32 compiler_probe_version=I386_COMPILER_PROBE_VERSION;
#assert sizeof(CI386CompilerProbe)==44
I64 Main(CI386CompilerProbe *probe,I64 bytes)
{
  if(!probe || bytes!=sizeof(CI386CompilerProbe) || probe->bytes!=bytes ||
      probe->version!=compiler_probe_version || !probe->heap || !probe->compiler ||
      !probe->symbols || !probe->i64_type || !probe->runtime_image ||
      probe->phase<0 || probe->phase>1) return 0;
  ProbeTokens(probe);
  return 1;
}
#include "/Compiler/ControlInit.HC"
U0 ProbeTokens(CI386CompilerProbe *probe)
{//Exercise retained module code before startup and after task/IRQ activity.
  CCmpCtrl cc; CLexFile file;
  U8 input[10],output[4],ident[5],*bytes;
  CHash *ident_entry;
  I64 phase=probe->phase,i,ch,lines=0,used=probe->heap->used,allocations=probe->heap->allocations;
  Bool done=FALSE;
  U64 value;
  if(!probe->runtime_image || I386HeapSize(probe->heap,probe->runtime_image)!=probe->runtime_size ||
      probe->compiler->version!=I386_COMPILER_SERVICES_VERSION) KernelStop;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  input[0]='0'; input[1]='.'; input[2]='0'; input[3]='0'; input[4]='0'; input[5]='1'; input[6]=';'; input[7]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,probe->symbols,char_bmp_alpha_numeric);
  LexFileSeed(&file,input); cc.lex_include_stk=&file; cc.cur_buf_ptr=input;
  ch=I386LexRawChar(probe->heap,&cc,&lines);
  if(probe->compiler->number_token(probe->heap,&cc,ch,&lines)!=TK_F64 ||
      cc.cur_f64(U64)!=0x3F1A36E2EB1C432D || cc.last_U16!=';' || cc.cur_buf_ptr!=input+7) KernelStop;
  value=cc.cur_f64(U64);
  input[0]=92; input[1]='x'; input[2]='4'; input[3]='1'; input[4]=34; input[5]=';'; input[6]=0;
  cc.flags=CCF_DONT_FREE_BUF|CCF_IN_QUOTES; cc.dollar_cnt=0;
  LexFileSeed(&file,input); cc.cur_buf_ptr=input;
  if(probe->compiler->string_chunk(probe->heap,&cc,output,4,&done,&lines)!=2 || !done ||
      output[0]!='A' || output[1] || cc.cur_buf_ptr!=input+5 || lines ||
      probe->heap->used!=used || probe->heap->allocations!=allocations ||
      I386HeapSize(probe->heap,probe->runtime_image)!=probe->runtime_size || !I386HeapValid(probe->heap)) KernelStop;
  input[0]=92; input[1]='x'; input[2]='4'; input[3]='1'; input[4]='B'; input[5]=39; input[6]=59; input[7]=0;
  cc.flags=CCF_DONT_FREE_BUF; LexFileSeed(&file,input); cc.cur_buf_ptr=input;
  if(probe->compiler->char_token(probe->heap,&cc,&lines)!=TK_CHAR_CONST ||
      cc.cur_i64!=0x4241 || cc.last_U16!=59 || cc.cur_buf_ptr!=input+7 || lines ||
      probe->heap->used!=used || probe->heap->allocations!=allocations || !I386HeapValid(probe->heap)) KernelStop;
  input[0]='/'; input[1]='x'; input[2]=10; input[3]='<'; input[4]='<'; input[5]='='; input[6]=';'; input[7]=0;
  cc.flags=CCF_DONT_FREE_BUF; LexFileSeed(&file,input); cc.cur_buf_ptr=input;
  if(probe->compiler->punct_token(probe->heap,&cc,'/',&lines)!=-2 || lines!=1) KernelStop;
  ch=I386LexRawChar(probe->heap,&cc,&lines);
  if(probe->compiler->punct_token(probe->heap,&cc,ch,&lines)!=TK_SHL_EQU ||
      cc.last_U16!=59 || cc.cur_buf_ptr!=input+7 || lines!=1 ||
      probe->heap->used!=used || probe->heap->allocations!=allocations || !I386HeapValid(probe->heap)) KernelStop;
  input[0]=';'; input[1]=0;
  cc.flags=CCF_DONT_FREE_BUF|CCF_USE_LAST_U16; cc.last_U16=';';
  LexFileSeed(&file,input); cc.cur_buf_ptr=input+1;
  if(!I386LexIncludeCopy(probe->heap,&cc,"Probe","I64i",TRUE) ||
      !(cc.lex_include_stk->flags&LFSF_DEFINE) || cc.lex_include_stk->next!=&file) KernelStop;
  ch=I386LexRawChar(probe->heap,&cc,&lines);
  if(probe->compiler->ident_scan(probe->heap,&cc,ch,ident,5,&ident_entry,&lines)!=5 ||
      ident_entry!=probe->i64_type || cc.local_var_entry ||
      ident[0]!='I' || ident[1]!='6' || ident[2]!='4' || ident[3]!='i' || ident[4] ||
      cc.token!=TK_SHL_EQU || cc.last_U16!=59 || cc.cur_buf_ptr!=input+1 || cc.lex_include_stk!=&file ||
      probe->heap->used!=used || probe->heap->allocations!=allocations || !I386HeapValid(probe->heap)) KernelStop;
  KernelLog("RUNTIME PROBE "); KernelHex(phase); KernelLog(" ");
  KernelHex(value); KernelLog(" "); KernelHex(output[0]); KernelLog(" "); KernelHex(cc.cur_i64); KernelLog(" "); KernelHex(cc.token); KernelLog(" "); KernelHex(ident_entry(CHashClass *)->size); KernelLog("\n");
  ProbeIdent(probe);
  ProbeDefine(probe);
}
U0 ProbeIdent(CI386CompilerProbe *probe)
{
  CCmpCtrl cc; CLexFile file; CHashTable table; CHashDefineStr macro;
  CHash *bucket=0; U8 input[8],*bytes; U32 flags,string_value;
  I64 phase=probe->phase,i,ch,lines=0,width,used=probe->heap->used,allocations=probe->heap->allocations;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  bytes=&table; for(i=0;i<sizeof(CHashTable);i++) bytes[i]=0;
  bytes=&macro; for(i=0;i<sizeof(CHashDefineStr);i++) bytes[i]=0;
  table.body=&bucket; table.next=probe->symbols;
  macro.str="Type"; macro.data="I64i"; macro.type=HTT_DEFINE_STR; HashAdd(&macro,&table);
  input[0]='T'; input[1]='y'; input[2]='p'; input[3]='e'; input[4]=';'; input[5]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,&table,char_bmp_alpha_numeric);
  LexFileSeed(&file,input); cc.lex_include_stk=&file; cc.cur_buf_ptr=input; cc.token=77;
  ch=I386LexRawChar(probe->heap,&cc,&lines);
  if(probe->compiler->ident_token(probe->heap,&cc,ch,"Probe",&lines)!=-2 || cc.token!=77 || cc.cur_str ||
      cc.lex_include_stk==&file || !(cc.lex_include_stk->flags&LFSF_DEFINE) ||
      probe->heap->allocations!=allocations+3) KernelStop;
  ch=I386LexRawChar(probe->heap,&cc,&lines);
  if(probe->compiler->ident_token(probe->heap,&cc,ch,"Probe",&lines)!=TK_IDENT || cc.cur_str_len!=5 ||
      StrCmp(cc.cur_str,"I64i") || cc.hash_entry!=probe->i64_type || macro.use_cnt!=1 ||
      cc.lex_include_stk!=&file || cc.cur_buf_ptr!=input+5 || cc.last_U16!=';' ||
      I386HeapSize(probe->heap,cc.cur_str)!=5 || probe->heap->allocations!=allocations+1) KernelStop;
  width=cc.hash_entry(CHashClass *)->size;
  KernelLog("IDENT PROBE "); KernelHex(phase); KernelLog(" "); KernelHex(cc.token); KernelLog(" "); KernelHex(width); KernelLog("\n");
  input[0]='a'; input[1]=92; input[2]='0'; input[3]='b'; input[4]=34; input[5]=59; input[6]=0;
  cc.flags=CCF_DONT_FREE_BUF; LexFileSeed(&file,input); cc.cur_buf_ptr=input;
  if(probe->compiler->string_token(probe->heap,&cc,&lines)!=TK_STR || cc.cur_str_len!=4 ||
      cc.cur_str[0]!='a' || cc.cur_str[1] || cc.cur_str[2]!='b' || cc.cur_str[3] ||
      cc.hash_entry!=probe->i64_type || cc.cur_buf_ptr!=input+6 || cc.last_U16!=59 ||
      I386HeapSize(probe->heap,cc.cur_str)!=4 || probe->heap->allocations!=allocations+1) KernelStop;
  string_value=cc.cur_str(U32 *)[0];
  flags=I386IrqSave;
  if(!I386HeapFree(probe->heap,cc.cur_str)) KernelStop;
  cc.cur_str=0; cc.cur_str_len=0;
  I386IrqRestore(flags);
  if(probe->heap->used!=used || probe->heap->allocations!=allocations || !I386HeapValid(probe->heap)) KernelStop;
  KernelLog("STRING PROBE "); KernelHex(phase); KernelLog(" "); KernelHex(cc.token); KernelLog(" "); KernelHex(string_value); KernelLog("\n");
  macro.data="2e0"; cc.flags=CCF_DONT_FREE_BUF;
  input[0]='T'; input[1]='y'; input[2]='p'; input[3]='e'; input[4]=';'; input[5]=0;
  LexFileSeed(&file,input); cc.cur_buf_ptr=input;
  if(probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=TK_F64 ||
      cc.cur_f64(U64)!=0x4000000000000000 ||
      probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=59 ||
      probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=TK_EOF ||
      cc.lex_include_stk!=&file || cc.cur_str ||
      probe->heap->used!=used || probe->heap->allocations!=allocations || !I386HeapValid(probe->heap)) KernelStop;
  KernelLog("LEX PROBE "); KernelHex(phase); KernelLog(" "); KernelHex(cc.cur_f64(U64)); KernelLog("\n");

}

#include "/Compiler/Keywords.HH"
U0 ProbeDefine(CI386CompilerProbe *probe)
{
  CCmpCtrl cc; CLexFile file; CHashTable table; CHashGeneric keyword;
  CHash *bucket=0; CHashDefineStr *entry; U8 *bytes; U32 flags;
  I64 phase=probe->phase,i,lines=0,used=probe->heap->used,allocations=probe->heap->allocations;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  bytes=&table; for(i=0;i<sizeof(CHashTable);i++) bytes[i]=0;
  bytes=&keyword; for(i=0;i<sizeof(CHashGeneric);i++) bytes[i]=0;
  table.body=&bucket; table.next=probe->symbols;
  keyword.str="define"; keyword.type=HTT_KEYWORD; keyword.user_data0=KW_DEFINE; HashAdd(&keyword,&table);
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,&table,char_bmp_alpha_numeric);
  LexFileSeed(&file,"#define Type 3e0\nType;"); file.full_name="Probe";
  cc.lex_include_stk=&file; cc.cur_buf_ptr=file.buf;
  if(probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=TK_F64 ||
      cc.cur_f64(U64)!=0x4008000000000000) KernelStop;
  entry=bucket;
  if(entry==&keyword || entry->next!=&keyword || entry->type!=HTT_DEFINE_STR || entry->cnt!=-1 ||
      StrCmp(entry->str,"Type") || StrCmp(entry->data,"3e0") || StrCmp(entry->src_link,"FL:Probe,1") ||
      entry->idx || cc.cur_str || probe->heap->allocations!=allocations+4 ||
      probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=59 ||
      probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=TK_EOF) KernelStop;
  flags=I386IrqSave;
  bucket=&keyword; cc.hash_entry=0;
  if(!I386HeapFree(probe->heap,entry->str) || !I386HeapFree(probe->heap,entry->data) ||
      !I386HeapFree(probe->heap,entry->src_link) || !I386HeapFree(probe->heap,entry)) KernelStop;
  I386IrqRestore(flags);
  if(probe->heap->used!=used || probe->heap->allocations!=allocations || !I386HeapValid(probe->heap)) KernelStop;
  KernelLog("DEFINE PROBE "); KernelHex(phase); KernelLog(" "); KernelHex(cc.cur_f64(U64)); KernelLog("\n");
}
