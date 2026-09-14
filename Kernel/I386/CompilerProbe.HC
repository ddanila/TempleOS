//Synchronous compiler diagnostics, retained only between boot and task probes.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/CompilerProbe.HH"
#include "/Compiler/ControlInit.HH"
#include "/Compiler/CompilerA.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Hash.HH"
#include "/Kernel/I386/String.HH"
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
import U0 KernelLog(U8 *text);
import U0 KernelHex(U64 value);
import U0 KernelStop();
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
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
extern U0 ProbeConditional(CI386CompilerProbe *probe);
extern U0 ProbeIncludes(CI386CompilerProbe *probe);
extern U0 ProbeDiskIncludes(CI386CompilerProbe *probe);
extern U0 ProbeParserMemory(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer);
extern U0 ProbeExpression(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer);
extern U0 ProbeBackend(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer);
extern U0 ProbeEmit(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer);
extern U0 ProbeOptimize(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer);
extern U0 ProbeBranches(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer);
extern U0 ProbeCompilerUnwind(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer);
U32 compiler_probe_version=I386_COMPILER_PROBE_VERSION;
#assert sizeof(CI386CompilerProbe)==56
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
  ProbeConditional(probe);
  ProbeIncludes(probe);
  ProbeDiskIncludes(probe);
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
  CCmpCtrl cc; CLexFile file; CHashTable table;
  CHash *bucket=0; CHashDefineStr *entry; U8 *bytes; U32 flags;
  I64 phase=probe->phase,i,lines=0,used=probe->heap->used,allocations=probe->heap->allocations;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  bytes=&table; for(i=0;i<sizeof(CHashTable);i++) bytes[i]=0;
  table.body=&bucket; table.next=probe->symbols;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,&table,char_bmp_alpha_numeric);
  LexFileSeed(&file,"#define Type 3e0\nType;"); file.full_name="Probe";
  cc.lex_include_stk=&file; cc.cur_buf_ptr=file.buf;
  if(probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=TK_F64 ||
      cc.cur_f64(U64)!=0x4008000000000000) KernelStop;
  entry=bucket;
  if(!entry || entry->next || entry->type!=HTT_DEFINE_STR || entry->cnt!=-1 ||
      StrCmp(entry->str,"Type") || StrCmp(entry->data,"3e0") || StrCmp(entry->src_link,"FL:Probe,1") ||
      entry->idx || cc.cur_str || probe->heap->allocations!=allocations+4 ||
      probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=59 ||
      probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=TK_EOF) KernelStop;
  flags=I386IrqSave;
  bucket=0; cc.hash_entry=0;
  if(!I386HeapFree(probe->heap,entry->str) || !I386HeapFree(probe->heap,entry->data) ||
      !I386HeapFree(probe->heap,entry->src_link) || !I386HeapFree(probe->heap,entry)) KernelStop;
  I386IrqRestore(flags);
  if(probe->heap->used!=used || probe->heap->allocations!=allocations || !I386HeapValid(probe->heap)) KernelStop;
  KernelLog("DEFINE PROBE "); KernelHex(phase); KernelLog(" "); KernelHex(cc.cur_f64(U64)); KernelLog("\n");
}

U0 ProbeConditional(CI386CompilerProbe *probe)
{
  CCmpCtrl cc; CLexFile file; U8 *bytes; U32 flags;
  I64 i,lines=0,used=probe->heap->used,allocations=probe->heap->allocations;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,probe->symbols,char_bmp_alpha_numeric);
  LexFileSeed(&file,"#ifdef Missing 9 #else #ifdef I64i 3e0 #else 5e0 #endif #endif;");
  cc.lex_include_stk=&file; cc.cur_buf_ptr=file.buf;
  if(probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=TK_F64 ||
      cc.cur_f64(U64)!=0x4008000000000000 ||
      probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=59 ||
      probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=TK_EOF ||
      !cc.cur_str || probe->heap->allocations!=allocations+1) KernelStop;
  flags=I386IrqSave;
  if(!I386HeapFree(probe->heap,cc.cur_str)) KernelStop;
  cc.cur_str=0;
  I386IrqRestore(flags);
  if(probe->heap->used!=used || probe->heap->allocations!=allocations || !I386HeapValid(probe->heap)) KernelStop;
  KernelLog("CONDITIONAL PROBE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(cc.cur_f64(U64)); KernelLog("\n");
}

class CProbeIncludeContext { I64 calls; };
Bool ProbeIncludePush(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *name)
{
  CProbeIncludeContext *state=context;
  U8 *source=0;
  state->calls++;
  if(!StrCmp(name,"Outer")) source="11 #include \"Inner\" 33";
  else if(!StrCmp(name,"Inner")) source="#ifdef Missing #include \"Missing\" #else 22 #endif";
  if(!source) return FALSE;
  return I386LexIncludeCopy(heap,cc,name,source,FALSE);
}
U0 ProbeIncludes(CI386CompilerProbe *probe)
{
  CCmpCtrl cc; CLexFile file;
  CI386LexIncludeService service; CProbeIncludeContext state;
  U8 *bytes; U32 flags,initial_if=GetRFlags&0x200;
  I64 i,lines=0,used=probe->heap->used,allocations=probe->heap->allocations;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,probe->symbols,char_bmp_alpha_numeric);
  LexFileSeed(&file,"#include \"Outer\";"); cc.lex_include_stk=&file; cc.cur_buf_ptr=file.buf;
  state.calls=0; service.context=&state; service.push=&ProbeIncludePush;
  for(i=1;i<=3;i++)
    if(probe->compiler->next_token_with_includes(probe->heap,&cc,"Probe",&lines,&service)!=TK_I64 ||
        cc.cur_i64!=11*i || (GetRFlags&0x200)!=initial_if) KernelStop;
  if(probe->compiler->next_token_with_includes(probe->heap,&cc,"Probe",&lines,&service)!=59 ||
      probe->compiler->next_token_with_includes(probe->heap,&cc,"Probe",&lines,&service)!=TK_EOF ||
      state.calls!=2 || cc.lex_include_stk!=&file) KernelStop;
  cc.flags=CCF_DONT_FREE_BUF;
  LexFileSeed(&file,"#include \"Missing\" 44;"); cc.cur_buf_ptr=file.buf;
  if(probe->compiler->next_token_with_includes(probe->heap,&cc,"Probe",&lines,&service)!=-1 ||
      state.calls!=3 || cc.lex_include_stk!=&file || !cc.cur_str || StrCmp(cc.cur_str,"Missing") ||
      probe->compiler->next_token_with_includes(probe->heap,&cc,"Probe",&lines,&service)!=TK_I64 || cc.cur_i64!=44 ||
      probe->compiler->next_token_with_includes(probe->heap,&cc,"Probe",&lines,&service)!=59 ||
      probe->compiler->next_token_with_includes(probe->heap,&cc,"Probe",&lines,&service)!=TK_EOF) KernelStop;
  cc.flags=CCF_DONT_FREE_BUF;
  LexFileSeed(&file,"#include \"Outer\""); cc.cur_buf_ptr=file.buf;
  if(probe->compiler->next_token(probe->heap,&cc,"Probe",&lines)!=-4 ||
      state.calls!=3 || !cc.cur_str || StrCmp(cc.cur_str,"include")) KernelStop;
  flags=I386IrqSave;
  if(!I386HeapFree(probe->heap,cc.cur_str)) KernelStop;
  cc.cur_str=0;
  I386IrqRestore(flags);
  if(probe->heap->used!=used || probe->heap->allocations!=allocations ||
      !I386HeapValid(probe->heap) || (GetRFlags&0x200)!=initial_if ||
      I386HeapSize(probe->heap,probe->runtime_image)!=probe->runtime_size) KernelStop;
  KernelLog("INCLUDE PROBE "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(state.calls); KernelLog(" "); KernelHex(cc.cur_i64); KernelLog("\n");
}

U0 ProbeDiskIncludes(CI386CompilerProbe *probe)
{
  CI386Heap *heap=I386TaskSelf->memory;
  CCmpCtrl *cc; CLexFile *file; U8 *bytes,*name; U32 flags,saved_flags=GetRFlags;
  I64 size,attr;
  I64 i,lines=0,used,allocations,refs=I386TaskSelf->lifetime_refs;
  if(!heap) heap=probe->heap;
  used=heap->used; allocations=heap->allocations;
  if(!probe->disk_include || !probe->disk_include->push || !probe->files || !probe->files->read) KernelStop;
  if(probe->phase) SetRFlags(saved_flags|0x200);
  size=-1; attr=-1; name=0;
  bytes=probe->files->read(heap,"C:/Probe/Bad.HC",&size,&attr,&name);
  if(!bytes || size!=3 || bytes[0]!='9' || bytes[1]!='9' || bytes[2]!=10 || bytes[3] ||
      !name || StrCmp(name,"C:/Probe/Bad.HC") || !(attr&0x800) ||
      (GetRFlags&0x200)!=(probe->phase*0x200)) KernelStop;
  flags=I386IrqSave;
  if(!I386HeapFree(heap,bytes) || !I386HeapFree(heap,name)) KernelStop;
  I386IrqRestore(flags);
  size=-1; attr=-1; name=0;
  if(probe->files->read(heap,"C:/Probe/Bad.HC.Z",&size,&attr,&name) ||
      size!=-1 || attr!=-1 || name || (GetRFlags&0x200)!=(probe->phase*0x200)) KernelStop;
  SetRFlags(saved_flags);
  KernelLog("DISK READ "); KernelHex(probe->phase); KernelLog("\n");
  cc=probe->files->control_new("#include \"C:/Probe/Outer\";",CCF_DONT_FREE_BUF,"Probe/Control.HC");
  if(!cc || !I386TaskSelf->hash_table || cc->htc.glbl_hash_table!=I386TaskSelf->hash_table ||
      (!probe->phase && I386TaskSelf->hash_table!=probe->symbols) ||
      (probe->phase && (I386TaskSelf->hash_table==probe->symbols || I386TaskSelf->hash_table->next!=probe->symbols))) KernelStop;
  file=cc->lex_include_stk;
  if(StrCmp(file->full_name,"C:/Probe/Control.HC") || I386TaskSelf->lifetime_refs!=refs+1) KernelStop;
  if(!probe->compiler->control_enter(heap,cc,0,0) || I386TaskSelf->last_cc!=cc ||
      I386TaskSelf->active_controls!=1) KernelStop;
  {
    if(GetRFlags&0x200) KernelStop;
    for(i=1;i<=3;i++)
      if(probe->compiler->next_token_with_includes(heap,cc,"Probe",&lines,probe->disk_include)!=TK_I64 ||
          cc->cur_i64!=11*i) KernelStop;
    if(probe->compiler->next_token_with_includes(heap,cc,"Probe",&lines,probe->disk_include)!=59 ||
        probe->compiler->next_token_with_includes(heap,cc,"Probe",&lines,probe->disk_include)!=TK_EOF ||
        cc->lex_include_stk!=file || lines!=68) KernelStop;
    cc->flags=CCF_DONT_FREE_BUF;
    LexFileSeed(file,"#include \"C:/Probe/Bad\" 44;"); cc->cur_buf_ptr=file->buf;
    if(probe->compiler->next_token_with_includes(heap,cc,"Probe",&lines,probe->disk_include)!=-1 ||
        cc->lex_include_stk!=file ||
        probe->compiler->next_token_with_includes(heap,cc,"Probe",&lines,probe->disk_include)!=TK_I64 || cc->cur_i64!=44) KernelStop;
  }
  if(probe->phase) {
    cc->flags=CCF_DONT_FREE_BUF;
    LexFileSeed(file,"#include \"C:/Probe/Outer\";"); cc->cur_buf_ptr=file->buf;
    SetRFlags(saved_flags|0x200);
    for(i=1;i<=3;i++)
      if(!(GetRFlags&0x200) ||
          probe->compiler->next_token_with_includes(heap,cc,"Probe",&lines,probe->disk_include)!=TK_I64 ||
          cc->cur_i64!=11*i || !(GetRFlags&0x200)) KernelStop;
    if(probe->compiler->next_token_with_includes(heap,cc,"Probe",&lines,probe->disk_include)!=59 ||
        probe->compiler->next_token_with_includes(heap,cc,"Probe",&lines,probe->disk_include)!=TK_EOF ||
        cc->lex_include_stk!=file || !(GetRFlags&0x200) || lines!=136) KernelStop;
    SetRFlags(saved_flags);
    KernelLog("DISK IF PRESERVED\n");
  }
  ProbeCompilerUnwind(probe,heap,cc);
  if(!probe->compiler->control_leave(heap,cc) || I386TaskSelf->active_controls ||
      I386TaskSelf->last_cc!=&I386TaskSelf->next_cc) KernelStop;
  if(!probe->compiler->control_del(heap,cc,0,0) || I386TaskSelf->lifetime_refs!=refs) KernelStop;
  if(heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
  KernelLog("DISK INCLUDE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(lines); KernelLog("\n");
}

U0 ProbeCompilerUnwind(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{//Use the resident exception runtime and recover without ending the compilation.
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *child;
  CCodeCtrl *saved;
  CIntermediateCode *retired;
  CLexFile *outer_file=outer->lex_include_stk;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  I64 lines=0,accepted=0;
  U32 flags=GetRFlags;
  child=probe->files->control_new("#include \"C:/Probe/Bad.HC.Z\";",CCF_DONT_FREE_BUF,"Probe/Failure.HC");
  if(!child || !probe->compiler->control_enter(heap,child,0,0)) KernelStop;
  child->last_line_num=0x100000002; child->pass_trace=1; child->lock_cnt=1;
  if(!probe->compiler->code_add(heap,child,0x0A,0x123456789ABCDEF0,probe->i64_type,0) ||
      !probe->compiler->code_add(heap,child,0x02,0,probe->i64_type,0) ||
      !probe->compiler->code_misc(heap,child,CMT_LABEL) ||
      !probe->compiler->code_save(heap,child) || !probe->compiler->code_push(heap,child)) KernelStop;
  retired=child->coc.coc_head.next;
  child->coc.coc_head.last->t.arg1_tree=retired;
  if(!probe->compiler->code_retire(heap,child,retired) ||
      child->coc.coc_head.last->t.arg1_tree->ic_data!=0x123456789ABCDEF0) KernelStop;
  SetRFlags((flags&~0x200)|(probe->phase*0x200));
  try {
    if(probe->compiler->next_token_with_includes(heap,child,"Probe",&lines,probe->disk_include)!=-1) KernelStop;
    throw('Compiler',TRUE);
    KernelStop;
  } catch {
    if(task->except_ch!='Compiler' || task->last_cc!=child || task->active_controls!=2 ||
        !probe->compiler->control_unwind(task,outer) ||
        (GetRFlags&0x200)!=(probe->phase*0x200)) KernelStop;
    task->catch_except=TRUE; accepted=1;
  }
  if(!accepted || task->except_top || task->last_cc!=outer || task->active_controls!=1 ||
      task->lifetime_refs!=refs || outer->lex_include_stk!=outer_file ||
      heap->used!=used || heap->allocations!=allocations) KernelStop;
  child=probe->files->control_new("42;",CCF_DONT_FREE_BUF,"Probe/Retry.HC");
  if(!child || !probe->compiler->control_enter(heap,child,0,0) ||
      probe->compiler->next_token_with_includes(heap,child,"Probe",&lines,probe->disk_include)!=TK_I64 ||
      child->cur_i64!=42 ||
      !probe->compiler->code_add(heap,child,0x0A,child->cur_i64,probe->i64_type,0) ||
      !(saved=probe->compiler->code_save(heap,child)) ||
      !probe->compiler->code_append(heap,child,saved) || !probe->compiler->code_push(heap,child) ||
      !(saved=probe->compiler->code_pop(heap,child)) || !probe->compiler->code_free(heap,child,saved) ||
      !probe->compiler->code_retire(heap,child,child->coc.coc_head.next) ||
      !probe->compiler->code_discard(heap,child,0,0) ||
      child->coc.coc_head.next!=&child->coc.coc_head.next ||
      !probe->compiler->control_unwind(task,outer) ||
      task->last_cc!=outer || task->lifetime_refs!=refs || task->active_controls!=1 ||
      heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
  ProbeBranches(probe,heap,outer);
  ProbeOptimize(probe,heap,outer);
  ProbeEmit(probe,heap,outer);
  ProbeBackend(probe,heap,outer);
  ProbeExpression(probe,heap,outer);
  ProbeParserMemory(probe,heap,outer);
  SetRFlags(flags);
  KernelLog("COMPILER RECOVERY "); KernelHex(probe->phase); KernelLog("\n");
}

U0 ProbeBranches(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{//A failed label allocation must unwind the partially rewritten optimizer graph.
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CIntermediateCode *left,*right,*split1,*split2,*predicate,*branch;
  CCodeMisc *target;
  U8 *fill,*block,*next;
  I64 attempt,size,accepted,used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  for(attempt=0;attempt<2;attempt++) {
    cc=probe->files->control_new("",CCF_DONT_FREE_BUF,"Probe/Branches.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    target=probe->compiler->code_misc(heap,cc,CMT_LABEL);
    left=probe->compiler->code_add(heap,cc,IC_IMM_I64,1,probe->i64_type,0);
    split1=probe->compiler->code_add(heap,cc,IC_NOP1,0,probe->i64_type,0);
    right=probe->compiler->code_add(heap,cc,IC_IMM_I64,2,probe->i64_type,0);
    split2=probe->compiler->code_add(heap,cc,IC_NOP1,0,probe->i64_type,0);
    predicate=probe->compiler->code_add(heap,cc,IC_OR_OR,0,probe->i64_type,0);
    branch=probe->compiler->code_add(heap,cc,IC_BR_ZERO,target,probe->i64_type,0);
    if(!target || !left || !split1 || !right || !split2 || !predicate || !branch) KernelStop;
    predicate->t.arg1_tree=left; predicate->t.arg2_tree=right;
    predicate->t.arg1_class=predicate->t.arg2_class=probe->i64_type;
    fill=0; accepted=0;
    try {
      if(!attempt)
        for(size=8192;size>=8;size>>=1)
          while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
      if(probe->compiler->code_branch(heap,cc,branch)!=split2 || !attempt ||
          branch->ic_code!=IC_LABEL || split1->ic_code!=IC_BR_NOT_ZERO ||
          split1->ic_data!=branch->ic_data || split2->ic_code!=IC_BR_ZERO ||
          split2->ic_data!=target || predicate->t.arg1_tree!=left) KernelStop;
      accepted=1;
    } catch {
      if(attempt || task->except_ch!='OutMem' || task->last_cc!=cc ||
          task->active_controls!=2 || predicate->t.arg2_tree!=right ||
          I386HeapSize(heap,predicate)<sizeof(CIntermediateCode)) KernelStop;
      task->catch_except=TRUE; accepted=1;
    }
    while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    if(!accepted || task->except_top || !probe->compiler->control_unwind(task,outer) ||
        task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  }
  KernelLog("BRANCH RECOVERY "); KernelHex(probe->phase); KernelLog("\n");
}

#include "/Kernel/I386/CompilerOptProbe.HC"

#include "/Kernel/I386/CompilerEmitProbe.HC"

#include "/Kernel/I386/CompilerBackendProbe.HC"

#include "/Kernel/I386/CompilerExpressionProbe.HC"

#include "/Kernel/I386/CompilerParserMemoryProbe.HC"
