//Public-control compiler workspace. Every emitter allocation is tracked until
//cleanup or explicit publication into the caller's AOT/symbol ownership.
class CPCBAllocation { CPCBAllocation *next; U8 *data; };
class CPCBReference {
  CPCBReference *next; CHashSrcSym *original; CHashFun function; U8 *target;
};
class CPCBState {
  CI386Backend backend; CPCBAllocation *allocations; CPCBReference *references;
  CHashTable helpers; CHash *helper_body[16]; Bool aot;
};
U8 *PCBAlloc(U8 *context,I64 bytes)
{
  CPCBState *state=context;CPCBAllocation *record=CAlloc(sizeof(CPCBAllocation));
  try{record->data=CAlloc(bytes);}catch{Free(record);}
  record->next=state->allocations;state->allocations=record;return record->data;
}
Bool PCBOwned(CPCBState *state,U8 *data)
{
  CPCBAllocation *record;
  for(record=state->allocations;record;record=record->next)if(record->data==data)return TRUE;
  return FALSE;
}
U0 PCBTake(CPCBState *state,U8 *data)
{
  CPCBAllocation **link=&state->allocations,*record;
  while(*link){record=*link;if(record->data==data){*link=record->next;Free(record);return;}link=&record->next;}
}
U0 PCBFree(U8 *context,U8 *data)
{
  CPCBState *state=context;
  if(data){if(!PCBOwned(state,data))throw('Compiler');PCBTake(state,data);Free(data);}
}
U8 *PCBString(CPCBState *state,U8 *text)
{I64 size=StrLen(text)+1;U8 *result=PCBAlloc(state,size);MemCpy(result,text,size);return result;}
CPCBReference *PCBReference(CPCBState *state,CHashSrcSym *original,Bool helper=FALSE)
{
  CPCBReference *reference;CHashFun *fun;CHashGlblVar *var;
  if(!original)throw('Compiler');
  for(reference=state->references;reference;reference=reference->next)
    if(reference->original==original){if(helper)reference->function.type|=HTF_IMPORT;return reference;}
  reference=PCBAlloc(state,sizeof(CPCBReference));reference->original=original;
  if(original->type&HTT_FUN){
    fun=original;if(Bt(&fun->flags,Ff_INTERNAL))throw('Compiler');
    MemCpy(&reference->function,fun,sizeof(CHashFun));reference->target=fun->exe_addr;
  }else{
    MemCpy(&reference->function,original,sizeof(CHashSrcSym));
    if(original->type&HTT_GLBL_VAR){var=original;reference->target=var->data_addr;}
    else if(original->type&HTT_EXPORT_SYS_SYM)reference->target=original(CHashExport*)->val;
    else throw('Compiler');
  }
  if(!state->aot || helper)reference->function.type|=HTF_IMPORT;
  reference->function.ie_lst=NULL;reference->function.ext_lst=NULL;
  reference->next=state->references;state->references=reference;return reference;
}
U0 PCBPrepare(CPCBState *state,CCmpCtrl *cc)
{
  CIntermediateCode *node;CHashFun *fun;CPCBReference *reference,**stack;
  I64 depth=0,maximum=0;
  for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next){
    if(node->ic_code==IC_CALL_START){depth++;if(depth>maximum)maximum=depth;}
    else if(node->ic_code==IC_CALL_END){if(!depth)throw('Compiler');depth--;}
  }
  if(depth)throw('Compiler');stack=PCBAlloc(state,(maximum+1)*sizeof(CPCBReference*));
  for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next){
    if(node->ic_code==IC_ADDR_IMPORT){reference=PCBReference(state,node->ic_data);node->ic_data=&reference->function;}
    else if(node->ic_code==IC_CALL_START){
      fun=node->ic_data;reference=NULL;
      if(!Bt(&fun->flags,Ff_INTERNAL)){reference=PCBReference(state,fun);node->ic_data=&reference->function;}
      stack[depth++]=reference;
    }else if(node->ic_code==IC_CALL || node->ic_code==IC_CALL_EXTERN || node->ic_code==IC_CALL_IMPORT || node->ic_code==IC_CALL_INDIRECT2){
      if(!depth || !(reference=stack[depth-1]))throw('Compiler');
      if(!state->aot){
        if(node->ic_code==IC_CALL_INDIRECT2)node->ic_data=&reference->original(CHashFun*)->exe_addr;
        else{if(!reference->target)throw('Compiler');node->ic_code=IC_CALL_IMPORT;node->ic_data=&reference->function;}
      }else if(node->ic_code!=IC_CALL && node->ic_code!=IC_CALL_INDIRECT2)node->ic_data=&reference->function;
    }else if(node->ic_code==IC_CALL_END){
      if(!depth)throw('Compiler');reference=stack[--depth];if(reference)node->ic_data=&reference->function;
    }
  }
  PCBFree(state,stack);
}
U0 PCBHelpers(CPCBState *state,CCmpCtrl *cc)
{
  U8 *name="I386F64Abs\0I386F64Sqrt\0I386F64Add\0I386F64Sub\0I386F64Mul\0I386F64Div\0I386F64Mod\0I386F64FromI64\0I386F64ToI64\0I386F64Compare\0";
  I64 i;CHashFun *fun;CPCBReference *reference;
  state->helpers.mask=15;state->helpers.body=state->helper_body;state->helpers.next=cc->htc.hash_table_lst;
  for(i=0;i<10;i++){
    fun=HashFind(name,cc->htc.hash_table_lst,HTT_FUN);reference=PCBReference(state,fun,TRUE);
    if(!reference->target)throw('Compiler');HashAdd(&reference->function,&state->helpers);while(*name++);
  }
  cc->htc.hash_table_lst=&state->helpers;
}
U0 PCBFold(U8 *context,CCmpCtrl *cc){OptPass012(cc);}
U0 PCBAssembly(U8 *context,CCmpCtrl *cc,CI386Out *out,CAOT *aot,I64 pass)
{CPCBState *state=context;I386AsmCore(&state->backend,cc,out,aot,pass);}
U0 PCBReport(U8 *context,I64 reason,CIntermediateCode *node,U8 *name)
{
  CPCBState *state=context;I64 opcode=0;if(node)opcode=node->ic_code;
  PrintErr("i386 backend reason %d opcode %X",reason,opcode);if(name)PrintErr(" %s",name);PrintErr("\n");
  LexExcept(state->backend.cc,"Compiler code generation at ");
}
U0 PCBLink(CPCBState *state,U8 *code,I64 bytes)
{
  CPCBReference *reference;CAOTImportExport *record;I64 offset,value,site;
  for(reference=state->references;reference;reference=reference->next)
    for(record=reference->function.ie_lst;record;record=record->next){
      offset=record->rip;if(offset<0 || offset>bytes-4)throw('Compiler');
      if(record->type==IET_REL_I32 || record->type==IET_I386_REL32_ADDR){value=reference->target;site=code+offset+4;value-=site;}
      else if(record->type==IET_IMM_U32 && reference->original->type&HTT_FUN)value=&reference->original(CHashFun*)->exe_addr;
      else throw('Compiler');
      MemCpy(code+offset,&value,4);
    }
}
U0 PCBQueue(CPCBState *state,CAOT *packet,CAOTImportExport *record,U8 *name)
{
  if(name)record->str=PCBString(state,name);
  record->aot=packet;QueIns(record,packet->last_ie);
}
U0 PCBStage(CPCBState *state,CAOT *packet,CAOT *emitted)
{
  CPCBReference *reference;CAOTImportExport *record,*next;U8 *name;
  for(reference=state->references;reference;reference=reference->next){
    name=reference->original->import_name;if(!name)name=reference->original->str;
    for(record=reference->function.ie_lst;record;record=next){next=record->next;PCBQueue(state,packet,record,name);}
    reference->function.ie_lst=NULL;
  }
  for(record=emitted->next_ie;record!=&emitted->next_ie;record=next){
    next=record->next;QueRem(record);
    if(record->type==IET_I386_BREAK_POLL){record->type=IET_REL_I32;PCBQueue(state,packet,record,"_COMPILER_BREAK_POLL");}
    else PCBQueue(state,packet,record,NULL);
  }
}
U0 PCBPublish(CPCBState *state,CAOT *staged,CAOT *destination)
{
  CPCBReference *reference;CExternUsage *usage,*next,*tail;
  CAOTImportExport *record,*after;
  //Validate all transfers before the no-allocation publication phase.
  for(record=staged->next_ie;record!=&staged->next_ie;record=record->next)
    if(!PCBOwned(state,record) || record->str && !PCBOwned(state,record->str))throw('Compiler');
  for(reference=state->references;reference;reference=reference->next)
    for(usage=reference->function.ext_lst;usage;usage=usage->next)
      if(!(reference->original->type&HTT_FUN) || !PCBOwned(state,usage))throw('Compiler');
  for(reference=state->references;reference;reference=reference->next){
    tail=NULL;
    for(usage=reference->function.ext_lst;usage;usage=next){next=usage->next;PCBTake(state,usage);tail=usage;}
    if(tail){tail->next=reference->original(CHashFun*)->ext_lst;reference->original(CHashFun*)->ext_lst=reference->function.ext_lst;}
  }
  for(record=staged->next_ie;record!=&staged->next_ie;record=after){
    after=record->next;QueRem(record);if(record->str)PCBTake(state,record->str);PCBTake(state,record);
    record->aot=destination;QueIns(record,destination->last_ie);
  }
}
U8 *NativeSystemCOCCompile(CCmpCtrl *cc,I64 *_code_size,CDbgInfo **_dbg,I64 *_type)
{
  CPCBState state;CI386Backend *backend=&state.backend;CI386Out out;CI386CompileFrame frame;
  CAOT emitted,staged,*old_aot=cc->aot;CAOTCtrl ctrl,*old_ctrl=cc->aotc;
  CHashTable *old_hash=cc->htc.hash_table_lst;CPCBAllocation *allocation;
  I64 flags=cc->flags,old_pass=cc->pass,exception=0,errors=cc->error_cnt,lines=0,i,base,value,site;CIntermediateCode *node;
  U8 *result=NULL;CDbgInfo *debug=NULL;CAOTImportExport *record;Bool failed=FALSE,has_data=FALSE;
  MemSet(&state,0,sizeof(state));MemSet(&frame,0,sizeof(frame));MemSet(&emitted,0,sizeof(emitted));
  MemSet(&staged,0,sizeof(staged));MemSet(&ctrl,0,sizeof(ctrl));I386OutInit(&out);
  QueInit(&emitted.next_ie);QueInit(&staged.next_ie);state.aot=(flags&CCF_AOT_COMPILE)!=0;frame.previous_fun=cc->htc.fun;
  for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next)if(node->ic_code==IC_STR_CONST)has_data=TRUE;
  if(state.aot){if(!old_aot || !old_ctrl)throw('Compiler');ctrl.rip=old_ctrl->rip;}
  if(_code_size)*_code_size=0;if(_dbg)*_dbg=NULL;if(_type)*_type=RT_I64;
  backend->initialize_variables=sys_var_init_flag;backend->variable_init_value=sys_var_init_val;
  backend->cc=cc;backend->out=&out;backend->types=cmp.internal_types;backend->context=&state;
  backend->allocate=&PCBAlloc;backend->release=&PCBFree;backend->fold=&PCBFold;
  backend->assembly=&PCBAssembly;backend->report=&PCBReport;backend->break_poll=native_jit_support.poll;
  backend->break_flags_offset=offset(CTask.task_flags);
  try{
    cc->aot=&emitted;cc->aotc=&ctrl;cc->flags=flags&~(CCF_EXE_BLK|CCF_TARGET_HOST_CONST)|CCF_TARGET_I386|CCF_AOT_COMPILE|CCF_MODULE_SOURCE;
    PCBPrepare(&state,cc);PCBHelpers(&state,cc);I386CompileFrameOpen(backend,&frame);
    if(_dbg){
      if(cc->min_line<0 || cc->max_line<cc->min_line || cc->max_line>U32_MAX)throw('Compiler');
      lines=cc->max_line-cc->min_line+1;
      if(lines>(I32_MAX-offset(CDbgInfo.body))/4-1)throw('Compiler');
      debug=CAlloc(offset(CDbgInfo.body)+4*(lines+1));debug->min_line=cc->min_line;debug->max_line=cc->max_line;debug->body[0]=1;
      backend->debug=debug;
    }
    PCBEmit(backend,sizeof(CI386Backend));
    if(state.aot)result=CAlloc((out.count+7)&~7);else result=CAlloc((out.count+7)&~7,Fs->code_heap);
    MemCpy(result,out.data,out.count);
    for(record=emitted.next_ie;record!=&emitted.next_ie;record=record->next){
      if(record->type==IET_I386_DATA){if(record->rip<ctrl.rip || record->flags<0 || record->rip-ctrl.rip>out.count-record->flags)throw('Compiler');}
      else if(!state.aot && record->type==IET_I386_BREAK_POLL){
        if(record->rip<0 || record->rip>out.count-4)throw('Compiler');
        value=native_jit_support.poll;site=result+record->rip+4;value-=site;MemCpy(result+record->rip,&value,4);
      }else if(!state.aot)throw('Compiler');
    }
    if(state.aot)PCBStage(&state,&staged,&emitted);else PCBLink(&state,result,out.count);
    if(Bt(&cc->opts,OPTf_TRACE))Un(result,out.count,32);
    if(debug){base=result;if(state.aot)base=ctrl.rip;for(i=0;i<lines;i++)if(debug->body[i])debug->body[i]=base+debug->body[i]-1;debug->body[lines]=base+out.count;}
  }catch{failed=TRUE;exception=Fs->except_ch;Fs->catch_except=TRUE;}
  I386CompileFrameClose(backend,&frame);cc->aot=old_aot;cc->aotc=old_ctrl;cc->htc.hash_table_lst=old_hash;
  cc->flags=flags|cc->flags&CCF_NOT_CONST;if(has_data && !failed)cc->flags|=CCF_HAS_MISC_DATA;
  try{
    for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next)
      if(node->ic_code==IC_ASM && node->ic_data){I386AsmFree(node->ic_data);node->ic_data=0;}
    COCDel(cc,&cc->coc);
  }catch{if(!failed){failed=TRUE;exception=Fs->except_ch;}Fs->catch_except=TRUE;}
  if(!failed && state.aot){try{PCBPublish(&state,&staged,old_aot);}catch{failed=TRUE;exception=Fs->except_ch;Fs->catch_except=TRUE;}}
  while(state.allocations){allocation=state.allocations;state.allocations=allocation->next;Free(allocation->data);Free(allocation);}
  Free(out.data);
  if(failed){cc->pass=old_pass;Free(result);Free(debug);if(exception=='Compiler' && cc->error_cnt==errors)cc->error_cnt++;throw(exception);}
  cc->pass=10;cc->saved_pass_trace=cc->pass_trace;if(!state.aot && frame.previous_fun)Fs->last_fun=frame.previous_fun;
  if(_type)*_type=frame.type->raw_type;if(_code_size)*_code_size=out.count;if(_dbg)*_dbg=debug;
  return result;
}
