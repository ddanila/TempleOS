public extern U64 I386F64Abs(U64 value);
public extern U64 I386F64Sqrt(U64 value);
public extern U64 I386F64Add(U64 a,U64 b);
public extern U64 I386F64Sub(U64 a,U64 b);
public extern U64 I386F64Mul(U64 a,U64 b);
public extern U64 I386F64Div(U64 a,U64 b);
public extern U64 I386F64Mod(U64 a,U64 b);
public extern U64 I386F64FromI64(I64 value);
public extern I64 I386F64ToI64(U64 value);
public extern I64 I386F64Compare(U64 a,U64 b);
//Diagnostic adapter: public allocations and the complete shared target backend.
#include "/Compiler/I386/Emit.HC"
#include "/Compiler/CodeLabel.HC"
#define I386_DIV_SOURCE_BUILD 1
#include "/Compiler/I386/DivideTemplate.HC"
#include "/Compiler/I386/BackendCore.HC"
#include "/Compiler/I386/AsmCore.HC"
class PBAllocation { PBAllocation *next; U8 data[0]; };
class PBReference { PBReference *next; CHashFun *original; CHashFun function; U8 *target; };
class PBState {
  CI386Backend backend; PBAllocation *allocations;
  PBReference *references; CHashTable helpers; CHash *helper_body[16];
};
U8 *PBAlloc(U8 *context,I64 bytes)
{
  PBState *state=context;
  PBAllocation *record=CAlloc(sizeof(PBAllocation)+bytes);
  record->next=state->allocations;state->allocations=record;
  return record->data;
}
U0 PBFree(U8 *context,U8 *allocation)
{
  PBState *state=context;PBAllocation **link=&state->allocations,*record;
  if(!allocation)return;
  while(*link) {
    record=*link;
    if(record->data==allocation){*link=record->next;Free(record);return;}
    link=&record->next;
  }
  throw('Compiler');
}
PBReference *PBReferenceNew(PBState *state,CHashFun *original)
{
  PBReference *reference;
  if(!original || Bt(&original->flags,Ff_INTERNAL))throw('Compiler');
  for(reference=state->references;reference;reference=reference->next)
    if(reference->original==original)return reference;
  reference=PBAlloc(state,sizeof(PBReference));
  reference->original=original;reference->target=original->exe_addr;
  MemCpy(&reference->function,original,sizeof(CHashFun));
  reference->function.type|=HTF_IMPORT;
  reference->function.ie_lst=NULL;reference->function.ext_lst=NULL;
  reference->next=state->references;state->references=reference;
  return reference;
}
U0 PBPrepareCalls(PBState *state,CCmpCtrl *cc)
{
  CIntermediateCode *node;CHashFun *function;PBReference *reference;
  I64 depth=0,maximum=0;PBReference **stack;
  for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next) {
    if(node->ic_code==IC_CALL_START) {depth++;if(depth>maximum)maximum=depth;}
    else if(node->ic_code==IC_CALL_END) {if(!depth)throw('Compiler');depth--;}
  }
  if(depth)throw('Compiler');
  stack=PBAlloc(state,(maximum+1)*sizeof(PBReference *));
  for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next) {
    if(node->ic_code==IC_CALL_START) {
      function=node->ic_data;reference=NULL;
      if(!Bt(&function->flags,Ff_INTERNAL)) {
        reference=PBReferenceNew(state,function);node->ic_data=&reference->function;
      }
      stack[depth++]=reference;
    } else if(node->ic_code==IC_CALL || node->ic_code==IC_CALL_EXTERN ||
        node->ic_code==IC_CALL_IMPORT || node->ic_code==IC_CALL_INDIRECT2) {
      if(!depth || !(reference=stack[depth-1]) || !reference->target)throw('Compiler');
      node->ic_code=IC_CALL_IMPORT;node->ic_data=&reference->function;
    } else if(node->ic_code==IC_CALL_END) {
      if(!depth)throw('Compiler');reference=stack[--depth];
      if(reference)node->ic_data=&reference->function;
    }
  }
  PBFree(state,stack);
}
U0 PBHelpers(PBState *state,CCmpCtrl *cc)
{
  U8 *name="I386F64Abs\0I386F64Sqrt\0I386F64Add\0I386F64Sub\0I386F64Mul\0I386F64Div\0I386F64Mod\0I386F64FromI64\0I386F64ToI64\0I386F64Compare\0";
  I64 i;CHashFun *function;PBReference *reference;
  state->helpers.mask=15;state->helpers.body=state->helper_body;
  state->helpers.next=cc->htc.hash_table_lst;
  for(i=0;i<10;i++) {
    function=HashFind(name,cc->htc.hash_table_lst,HTT_FUN);
    reference=PBReferenceNew(state,function);if(!reference->target)throw('Compiler');
    HashAdd(&reference->function,&state->helpers);
    while(*name++);
  }
  cc->htc.hash_table_lst=&state->helpers;
}
U0 PBLink(PBState *state,U8 *code,I64 bytes)
{
  PBReference *reference;CAOTImportExport *record;
  I64 offset;
  for(reference=state->references;reference;reference=reference->next)
    for(record=reference->function.ie_lst;record;record=record->next) {
      offset=record->rip;
      if(record->type!=IET_REL_I32 || offset<0 || offset>bytes-4)throw('Compiler');
      (code+offset)(U32 *)[0]=(reference->target+0)(U64)-(code+offset+4)(U64);
    }
}
U0 PBFold(U8 *context,CCmpCtrl *cc){OptPass012(cc);}
U0 PBAssembly(U8 *context,CCmpCtrl *cc,CI386Out *out,CAOT *aot,I64 pass)
{ PBState *state=context;I386AsmCore(&state->backend,cc,out,aot,pass); }
U0 PBReport(U8 *context,I64 reason,CIntermediateCode *node,U8 *name)
{
  PBState *state=context;
  state->backend.cc->error_cnt++;
  U8 *message=MStrPrint("PUBLIC BACKEND reason %d node %X\n",reason,node),*cursor=message;
  while(*cursor)OutU8(0xE9,*cursor++);Free(message);
}
U8 *COCCompile(CCmpCtrl *cc,I64 *_code_size,CDbgInfo **_dbg,I64 *_type)
{
  PBState state;CI386Backend *backend=&state.backend;CI386Out out;
  CHashFun fun,*old_fun=cc->htc.fun;
  CAOT aot,*old_aot=cc->aot;CAOTCtrl aotc,*old_aotc=cc->aotc;
  CIntermediateCode *node,*enter,*ret=NULL;
  CHashClass *type;PBAllocation *allocation;
  I64 flags=cc->flags,pass=cc->pass,exception=0;U8 *result=NULL;
  CHashTable *old_hash=cc->htc.hash_table_lst;
  Bool failed=FALSE;
  MemSet(&state,0,sizeof(state));MemSet(&fun,0,sizeof(fun));
  MemSet(&aot,0,sizeof(aot));MemSet(&aotc,0,sizeof(aotc));I386OutInit(&out);
  aot.next_ie=aot.last_ie=&aot.next_ie;
  if(_code_size)*_code_size=0;if(_dbg)*_dbg=NULL;
  backend->cc=cc;backend->out=&out;backend->types=cmp.internal_types;
  backend->context=&state;backend->allocate=&PBAlloc;backend->release=&PBFree;
  backend->fold=&PBFold;backend->assembly=&PBAssembly;backend->report=&PBReport;
  try {
    //The public expression wrapper supplies RETURN_VAL/RET, without a function.
    //Use a temporary target function context; never cast to a private control.
    enter=ICAdd(cc,IC_ENTER,0,NULL);ICDetach(enter);
    enter->last=&cc->coc.coc_head;enter->next=cc->coc.coc_head.next;
    enter->next->last=enter;cc->coc.coc_head.next=enter;
    for(node=enter->next;node!=&cc->coc.coc_head;node=node->next) {
      if(node->ic_code==IC_RETURN_VAL)ret=node;
      if(node->ic_code==IC_RET)node->ic_code=IC_LEAVE;
    }
    if(!ret)throw('Compiler');
    cc->pass=0;OptPass012(cc);OptPass012(cc);
    if(!ret->t.arg1_tree || !(type=I386ValueClass(backend,ret->t.arg1_tree)))throw('Compiler');
    fun.return_class=ret->ic_class=type;
    cc->htc.fun=&fun;cc->aot=&aot;cc->aotc=&aotc;
    cc->flags=flags&~(CCF_EXE_BLK|CCF_TARGET_HOST_CONST)|CCF_TARGET_I386|CCF_AOT_COMPILE;
    PBPrepareCalls(&state,cc);PBHelpers(&state,cc);
    I386BackendCore(backend);
    result=MAlloc(out.count,Fs->code_heap);MemCpy(result,out.data,out.count);
    PBLink(&state,result,out.count);
    if(_type)*_type=type->raw_type;if(_code_size)*_code_size=out.count;
  }catch{
    failed=TRUE;exception=Fs->except_ch;Fs->catch_except=TRUE;
    U8 *message=MStrPrint("PUBLIC BACKEND exception %X pass %d depth %d opcode %X\n",
      exception,backend->pass,backend->depth,backend->current),*cursor=message;
    while(*cursor)OutU8(0xE9,*cursor++);Free(message);
  }
  cc->htc.fun=old_fun;cc->aot=old_aot;cc->aotc=old_aotc;
  cc->flags=flags;cc->pass=pass;cc->htc.hash_table_lst=old_hash;
  while(state.allocations){allocation=state.allocations;state.allocations=allocation->next;Free(allocation);}
  Free(out.data);COCDel(cc,&cc->coc);
  if(failed){Free(result);throw(exception);}
  return result;
}
