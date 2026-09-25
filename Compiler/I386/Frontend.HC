extern U0 I386ExecutionBreakPoll();
//Retained compiler environment. Private symbols and temporaries belong to one cc.
#include "/Compiler/I386/Frontend.HH"
#include "/Kernel/I386/FileRuntime.HH"
#include "/Compiler/PrsFunction.HH"
#include "/Compiler/PrsStatement.HH"
#include "/Compiler/SymbolInit.HC"
#include "/Compiler/PrsBinary.HC"
#include "/Compiler/LexBackup.HC"
#include "/Compiler/I386/LexState.HC"
extern class CI386FrontendReloc;
extern class CI386FrontendAddress;
class CI386FrontendCode {
  CI386FrontendCode *next;
  CI386FrontendReloc *relocs;
  U8 *code;
  I64 bytes,data_start,raw_type,prior_misc;
  CHashClass *value_class;
};
class CI386FrontendReloc {
  CI386FrontendReloc *next;
  I64 offset,kind;
  U8 name[1];
};
class CI386FrontendAddress {
  CI386FrontendAddress *next;
  CHashFun fun;
  CHashFun *original;
  U8 *target;
};
class CI386FrontendFixup {
  CI386FrontendFixup *next;
  CHashFun *function;
  U8 *code;
  I64 offset,argument_count,flags;
  CHashClass *result_type;
  CHashClass *arguments[1];
};
class CI386FrontendResident {
  CI386FrontendResident *next;
  CHashSrcSym *declaration;
  CHashExport *export;
  I64 address;
};
class CI386FrontendCompletion {
  CI386FrontendCompletion *next;
  CHashClass *published,*staged;
};
class CI386Frontend {
  CI386Heap *heap;
  CCmpCtrl *cc;
  CI386LexIncludeService *includes;
  CI386FileServices *files;
  CI386LexIncludeService lex_services;
  CHashTable *table,*parent,*defines;
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsSymbolServices symbols;
  CPrsInitializerServices initializers;
  CPrsGlobalServices globals;
  CPrsFunctionServices functions;
  CPrsStatementServices statements;
  U32 binary_ops[TK_TKS_NUM];
  I64 lines;
  CI386FrontendCode *codes;
  CI386FrontendFixup *fixups;
  CI386FrontendResident *residents;
  CI386FrontendCompletion *completions;
  U8 *diagnostic_context;
  U0 (*diagnostic)(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message);
};
class CI386FrontendCall {
  CI386FrontendCall *next,*stack;
  CHashFun fun;
  U8 *target;
  CHashFun *original;
  Bool recursive,unresolved;
};
class CI386FrontendBound {
  CI386FrontendCall *calls;
  CI386FrontendAddress *address_refs;
  CHashFun fun;
  CAOT aot;
  CAOTCtrl aotc;
  CI386BackendStatus status;
  CI386Backend typer;
  CI386NativeBackend release_owner;
  CHashTable helpers;
  CHash *buckets[16];
  CHashFun functions[10];
  CMemberLst arguments[20];
  U8 *addresses[10];
};
extern I64 I386FrontendDirective(U8 *context,CCmpCtrl *cc,I64 keyword);
extern U0 I386FrontendStatementsInit(CI386Frontend *state);
U0 I386FrontendUndefined() { throw('Compiler',TRUE); }
U0 I386FrontendReport(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message)
{
  CI386Frontend *state=context;
  if(kind==2) {
    if(!(cc->opts&1<<OPTf_WARN_PAREN) || cc->lex_include_stk->flags&LFSF_DEFINE) return;
    message="Unnecessary parenthesis ";
  }
  if(state->diagnostic) state->diagnostic(state->diagnostic_context,cc,kind,message);
  if(!kind) { cc->error_cnt++; throw('Compiler',TRUE); }
  cc->warning_cnt++;
}
U0 I386FrontendUnavailable(CI386Frontend *state)
{ I386FrontendReport(state,state->cc,0,"Native frontend service unavailable"); }
U8 *I386FrontendAlloc(U8 *context,I64 bytes,Bool zeroed,Bool code_heap)
{
  CI386Frontend *state=context;
  U8 *result;
  if(!bytes) bytes=1;
  result=I386ParserAlloc(state->heap,state->cc,bytes,zeroed);
  if(!result) I386FrontendUnavailable(state);
  return result;
}
U8 *I386FrontendTypeAlloc(U8 *context,I64 bytes)
{ return I386FrontendAlloc(context,bytes,TRUE,FALSE); }
U0 I386FrontendFree(U8 *context,U8 *allocation)
{
  CI386Frontend *state=context;
  CI386FrontendCode **link=&state->codes,*record;
  CI386FrontendReloc *reloc,*next_reloc;
  CI386FrontendFixup **pending=&state->fixups,*fixup;
  while(fixup=*pending) {
    if(fixup->code==allocation) {
      *pending=fixup->next;
      if(!I386ParserFree(state->heap,state->cc,fixup)) I386FrontendUnavailable(state);
    } else pending=&fixup->next;
  }
  while(record=*link) {
    if(record->code==allocation) {
      *link=record->next;
      for(reloc=record->relocs;reloc;reloc=next_reloc) {
        next_reloc=reloc->next;
        if(!I386ParserFree(state->heap,state->cc,reloc)) I386FrontendUnavailable(state);
      }
      if(!I386ParserFree(state->heap,state->cc,record)) I386FrontendUnavailable(state);
      break;
    }
    link=&record->next;
  }
  if(!I386ParserFree(state->heap,state->cc,allocation)) I386FrontendUnavailable(state);
}
U8 *I386FrontendDuplicate(U8 *context,U8 *source)
{
  I64 i,length=StrLen(source)+1;
  U8 *result=I386FrontendAlloc(context,length,FALSE,FALSE);
  for(i=0;i<length;i++) result[i]=source[i];
  return result;
}
CHashClass *I386FrontendClassView(U8 *context,CHashClass *type)
{
  CI386Frontend *state=context;
  CI386FrontendCompletion *completion;
  CHashClass *base;
  if(!type || !(type->type&HTT_CLASS)) return type;
  base=type-type->ptr_stars_cnt;
  for(completion=state->completions;completion;completion=completion->next)
    if(base==completion->published) return completion->staged+type->ptr_stars_cnt;
  return type;
}
I64 I386FrontendLex(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  I64 token=I386ParserToken(state->heap,cc,"Frontend",&state->lines,state->includes);
  cc->hash_entry=I386FrontendClassView(state,cc->hash_entry);
  return token;
}
CIntermediateCode *I386FrontendAdd(U8 *context,CCmpCtrl *cc,I64 op,I64 value,CHashClass *type,I64 flags)
{
  CI386Frontend *state=context;
  CIntermediateCode *node=I386ICAdd(state->heap,cc,op,value,I386FrontendClassView(state,type),flags);
  if(!node) throw('OutMem',TRUE);
  return node;
}
U0 I386FrontendRetire(U8 *context,CCmpCtrl *cc,CIntermediateCode *node)
{
  CI386Frontend *state=context;
  if(!I386ICRetire(state->heap,cc,node)) I386FrontendUnavailable(state);
}
CCodeMisc *I386FrontendMisc(U8 *context,CCmpCtrl *cc,I64 kind)
{
  CI386Frontend *state=context;
  CCodeMisc *misc=I386COCMiscNew(state->heap,cc,kind);
  if(!misc) throw('OutMem',TRUE);
  return misc;
}
U0 I386FrontendInit(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  if(!I386COCInit(state->heap,cc)) I386FrontendUnavailable(state);
}
U0 I386FrontendPush(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  if(!I386COCPush(state->heap,cc)) throw('OutMem',TRUE);
}
U0 I386FrontendPop(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  CCodeCtrl *saved=I386COCPopNoFree(state->heap,cc);
  if(!saved || !I386COCHeaderFree(state->heap,cc,saved)) I386FrontendUnavailable(state);
}
U0 I386FrontendAppend(U8 *context,CCmpCtrl *cc,CCodeCtrl *saved)
{
  CI386Frontend *state=context;
  if(!I386COCAppend(state->heap,cc,saved)) I386FrontendUnavailable(state);
}
CIntermediateCode *I386FrontendOptimize(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  return I386OptPass012(state->heap,cc,state->expression.types);
}
Bool I386FrontendExpression(U8 *context,CCmpCtrl *cc,I64 *precedence,Bool end_exp,CPrsStk *stack)
{
  CI386Frontend *state=context;
  return I386ParseExpression(state->heap,cc,&state->expression,precedence,end_exp,stack);
}
CHashClass *I386FrontendType(U8 *context,CCmpCtrl *cc,CHashClass **first,I64 *mode,
  CMemberLst *member,U8 **ident,CHashFun **fun,CHashExport **export_entry,CArrayDim *dim,I64 flags)
{
  CI386Frontend *state=context;
  CHashClass *result;
  if(first) *first=I386FrontendClassView(state,*first);
  result=I386ParseType(state->heap,cc,&state->types,first,mode,member,ident,fun,export_entry,dim,flags);
  if(!result) I386FrontendUnavailable(state);
  return result;
}
U8 *I386FrontendString(U8 *context,CCmpCtrl *cc,I64 *size)
{
  U8 *text=cc->cur_str,*part,*joined;
  I64 length=cc->cur_str_len,count,i;
  cc->cur_str=0;
  while(I386FrontendLex(context,cc)==TK_STR) {
    part=cc->cur_str; count=cc->cur_str_len; cc->cur_str=0;
    if(length<1 || count<1 || length>0x7FFFFFFF-count) I386FrontendUnavailable(context);
    joined=I386FrontendAlloc(context,length+count-1,FALSE,FALSE);
    for(i=0;i<length-1;i++) joined[i]=text[i];
    for(i=0;i<count;i++) joined[length-1+i]=part[i];
    I386FrontendFree(context,text); I386FrontendFree(context,part);
    text=joined; length+=count-1;
  }
  if(size) *size=length;
  return text;
}
U0 I386FrontendHashAdd(U8 *context,CHash *entry,CHashTable *table)
{
  CI386Frontend *state=context;
  if(table!=state->table) I386FrontendUnavailable(state);
  HashAdd(entry,table);
}
U0 I386FrontendHashAfter(U8 *context,CHash *entry,CHash *after,CHashTable *table)
{ I386FrontendUnavailable(context); }
U0 I386FrontendSnapshot(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  if(!I386LexPush(state->heap,cc)) throw('OutMem',TRUE);
}
U0 I386FrontendDrop(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  if(!I386LexPop(state->heap,cc,FALSE)) I386FrontendUnavailable(state);
}
U0 I386FrontendRestore(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  if(!I386LexPop(state->heap,cc,TRUE)) I386FrontendUnavailable(state);
}
CMemberLst *I386FrontendMember(U8 *context,I64 register_hint)
{
  CMemberLst *member=I386FrontendAlloc(context,sizeof(CMemberLst),TRUE,FALSE);
  member->reg=register_hint; return member;
}
U0 I386FrontendMemberDiagnostic(U8 *context,Bool warning)
{
  CI386Frontend *state=context;
  I386FrontendReport(state,state->cc,warning,"Duplicate member");
}
U0 I386FrontendMemberAdd(U8 *context,CCmpCtrl *cc,CMemberLst *member,CHashClass *type,I64 mode)
{
  if(!MemberInsert(member,type,mode==PRS1B_LOCAL_VAR,FALSE,&I386FrontendMemberDiagnostic,context))
    I386FrontendUnavailable(context);
}
U0 I386FrontendHelpers(CI386FrontendBound *bound,CHashClass **types)
{
  U8 *name="I386F64Sqrt\0I386F64Abs\0I386F64Add\0I386F64Sub\0I386F64Mul\0I386F64Div\0I386F64Mod\0I386F64FromI64\0I386F64ToI64\0I386F64Compare";
  CHashFun *fun;
  CMemberLst *arg;
  I64 i,j,count,argument_type,result_type;
  bound->helpers.mask=15; bound->helpers.body=bound->buckets;
  bound->addresses[0]=&I386F64Sqrt; bound->addresses[1]=&I386F64Abs;
  bound->addresses[2]=&I386F64Add; bound->addresses[3]=&I386F64Sub;
  bound->addresses[4]=&I386F64Mul; bound->addresses[5]=&I386F64Div;
  bound->addresses[6]=&I386F64Mod; bound->addresses[7]=&I386F64FromI64;
  bound->addresses[8]=&I386F64ToI64; bound->addresses[9]=&I386F64Compare;
  for(i=0;i<10;i++,name+=StrLen(name)+1) {
    fun=&bound->functions[i]; count=2; argument_type=result_type=RT_U64;
    if(i<2 || i==7 || i==8) count=1;
    if(i==7) argument_type=RT_I64;
    if(i>=8) result_type=RT_I64;
    fun->str=name; fun->type=HTT_FUN|HTF_IMPORT;
    fun->arg_cnt=count; fun->return_class=types[result_type];
    fun->member_lst_and_root=&bound->arguments[i*2];
    for(j=0;j<count;j++) {
      arg=&bound->arguments[i*2+j]; arg->member_class=types[argument_type];
      if(j+1<count) arg->next=arg+1;
    }
    HashAdd(fun,&bound->helpers);
  }
}
CHashFun *I386FrontendFunctionAt(CI386Frontend *state,U8 *address)
{
  CHashTable *table;
  CHash *entry;
  CHashFun *found=0,*fun;
  I64 i;
  for(table=state->table;table;table=table->next)
    for(i=0;i<=table->mask;i++)
      for(entry=table->body[i];entry;entry=entry->next)
        if(entry->type&HTT_FUN) {
          fun=entry;
          if(fun->exe_addr==address) {
            if(found && found!=fun) I386FrontendUnavailable(state);
            found=fun;
          }
        }
  return found;
}
U0 I386FrontendCalls(CI386Frontend *state,CI386FrontendBound *bound,CCmpCtrl *cc)
{
  CIntermediateCode *node;
  CHashFun *fun;
  CI386FrontendCall *call,*stack=0;
  CI386FrontendAddress *address;
  U8 *destination,*source;
  I64 i;
  for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next) {
    if(node->ic_code==IC_CALL_START) {
      fun=node->ic_data;
      if(fun && Bt(&fun->flags,Ff_INTERNAL) && !I386IntrinsicValid(fun)) I386FrontendUnavailable(state);
      call=I386FrontendAlloc(state,sizeof(CI386FrontendCall),TRUE,FALSE);
      destination=&call->fun; source=fun;
      for(i=0;i<sizeof(CHashFun);i++) destination[i]=source[i];
      call->fun.ie_lst=0; call->fun.ext_lst=0;
      call->target=fun->exe_addr; call->recursive=fun==cc->htc.fun;
      call->original=fun;
      call->unresolved=!call->recursive && Bt(&fun->flags,Cf_EXTERN);
      call->next=bound->calls; bound->calls=call;
      call->stack=stack; stack=call;
      node->ic_data=&call->fun;
    } else if(node->ic_code==IC_CALL || node->ic_code==IC_CALL_EXTERN ||
        node->ic_code==IC_CALL_IMPORT || node->ic_code==IC_CALL_INDIRECT2) {
      if(!stack || !stack->recursive && (!stack->target || stack->fun.type&HTF_IMPORT))
        I386FrontendUnavailable(state);
      if(stack->unresolved && !I386ParserRecord(state->cc,stack->original))
        I386FrontendUnavailable(state);
      node->ic_code=IC_CALL_IMPORT;
    } else if(node->ic_code==IC_CALL_END) {
      if(!stack) I386FrontendUnavailable(state);
      node->ic_data=&stack->fun;
      stack=stack->stack;
    } else if(node->ic_code==IC_ABS_ADDR || node->ic_code==IC_ADDR_IMPORT) {
      if(node->ic_code==IC_ABS_ADDR) fun=I386FrontendFunctionAt(state,node->ic_data);
      else fun=node->ic_data;
      if(!fun || !fun->exe_addr || !(fun->type&HTT_FUN)) I386FrontendUnavailable(state);
      address=I386FrontendAlloc(state,sizeof(CI386FrontendAddress),TRUE,FALSE);
      destination=&address->fun; source=fun;
      for(i=0;i<sizeof(CHashFun);i++) destination[i]=source[i];
      address->fun.type|=HTF_IMPORT;
      address->fun.ie_lst=0; address->fun.ext_lst=0;
      address->original=fun; address->target=fun->exe_addr;
      address->next=bound->address_refs; bound->address_refs=address;
      node->ic_code=IC_ADDR_IMPORT; node->ic_data=&address->fun;
    } else if(node->ic_code==IC_HEAP_GLBL)
      I386FrontendUnavailable(state);
  }
  if(stack) I386FrontendUnavailable(state);
}
U0 I386FrontendRelocAdd(CI386Frontend *state,CI386FrontendCode *output,
  I64 offset,I64 kind,U8 *name)
{
  CI386FrontendReloc *reloc;
  I64 i,length=StrLen(name);
  if(length<1 || length>255 || offset<1 || offset>output->bytes-4 ||
      (kind!=I386_MODULE_REL32 && kind!=I386_MODULE_ADDRESS) ||
      (kind==I386_MODULE_REL32 && output->code[offset-1]!=0xE8) ||
      (kind==I386_MODULE_ADDRESS && output->code[offset-1]!=0x05))
    I386FrontendUnavailable(state);
  reloc=I386FrontendAlloc(state,sizeof(CI386FrontendReloc)+length,TRUE,FALSE);
  reloc->offset=offset; reloc->kind=kind;
  for(i=0;i<=length;i++) reloc->name[i]=name[i];
  reloc->next=output->relocs; output->relocs=reloc;
}
U0 I386FrontendLink(CI386Frontend *state,CI386FrontendBound *bound,CI386FrontendCode *output)
{
  CAOTImportExport *record,*next;
  CI386FrontendCall *call,*next_call;
  CI386FrontendAddress *address,*next_address;
  CI386FrontendFixup *fixup;
  CMemberLst *member;
  U8 *target;
  I64 i,j,offset,bytes=output->bytes;
  U8 *code=output->code;
  bound->release_owner.heap=state->heap; bound->release_owner.backend.cc=state->cc;
  for(i=0;i<10;i++) {
    record=bound->functions[i].ie_lst; bound->functions[i].ie_lst=0;
    while(record) {
      next=record->next; offset=record->rip;
      if(record->type!=IET_REL_I32 || offset<0 || offset>bytes-4) {
        I386FrontendUnavailable(state);
      }
      I386FrontendRelocAdd(state,output,offset,I386_MODULE_REL32,bound->functions[i].str);
      (code+offset)(U32 *)[0]=(bound->addresses[i]+0)(U64)-(code+offset+4)(U64);
      I386NativeBackendFree(&bound->release_owner,record);
      record=next;
    }
  }
  call=bound->calls; bound->calls=0;
  while(call) {
    next_call=call->next; target=call->target;
    if(call->recursive) target=code;
    record=call->fun.ie_lst;
    while(record) {
      next=record->next; offset=record->rip;
      if(record->type!=IET_REL_I32 || offset<0 || offset>bytes-4) I386FrontendUnavailable(state);
      I386FrontendRelocAdd(state,output,offset,I386_MODULE_REL32,call->original->str);
      if(call->unresolved) {
        if(call->fun.arg_cnt<0 || call->fun.arg_cnt>4095) I386FrontendUnavailable(state);
        fixup=I386FrontendAlloc(state,sizeof(CI386FrontendFixup)+call->fun.arg_cnt*sizeof(CHashClass *),TRUE,FALSE);
        fixup->function=call->original; fixup->code=code; fixup->offset=offset;
        fixup->argument_count=call->fun.arg_cnt; fixup->result_type=call->fun.return_class;
        fixup->flags=call->fun.flags&(FSG_FUN_FLAGS1|1<<Ff_DOT_DOT_DOT);
        member=call->fun.member_lst_and_root;
        for(j=0;j<fixup->argument_count;j++) {
          if(!member) I386FrontendUnavailable(state);
          fixup->arguments[j]=member->member_class; member=member->next;
        }
        fixup->next=state->fixups; state->fixups=fixup;
        target=&I386FrontendUndefined;
      }
      (code+offset)(U32 *)[0]=(target+0)(U64)-(code+offset+4)(U64);
      I386NativeBackendFree(&bound->release_owner,record); record=next;
    }
    I386FrontendFree(state,call); call=next_call;
  }
  address=bound->address_refs; bound->address_refs=0;
  while(address) {
    next_address=address->next; target=address->target;
    if(address->original==state->cc->htc.fun) target=code;
    record=address->fun.ie_lst;
    while(record) {
      next=record->next; offset=record->rip;
      if(record->type!=IET_I386_REL32_ADDR || offset<1 || offset>bytes-4)
        I386FrontendUnavailable(state);
      I386FrontendRelocAdd(state,output,offset,I386_MODULE_ADDRESS,address->original->str);
      (code+offset)(U32 *)[0]=(target+0)(U64)-(code+offset+4)(U64);
      I386NativeBackendFree(&bound->release_owner,record); record=next;
    }
    I386FrontendFree(state,address); address=next_address;
  }
  record=bound->aot.next_ie; bound->aot.next_ie=bound->aot.last_ie=&bound->aot.next_ie;
  while(record!=&bound->aot.next_ie) {
    next=record->next;
    I386NativeBackendFree(&bound->release_owner,record);
    record=next;
  }
}
CI386FrontendCode *I386FrontendOutput(CI386Frontend *state,CCmpCtrl *cc,CHashClass *type,I64 prior_misc)
{
  CI386FrontendBound *bound=I386FrontendAlloc(state,sizeof(CI386FrontendBound),TRUE,FALSE);
  CI386FrontendCode *result;
  CI386Out *out;
  CAOT *old_aot=cc->aot;
  CAOTCtrl *old_aotc=cc->aotc;
  CHashTable *old_hash=cc->htc.hash_table_lst;
  CAOTImportExport *metadata;
  I64 old_flags=cc->flags,old_pass=cc->pass,i;
  I64 mask=CCF_AOT_COMPILE|CCF_EXE_BLK|CCF_TARGET_HOST_CONST;
  bound->aot.next_ie=bound->aot.last_ie=&bound->aot.next_ie;
  cc->aot=&bound->aot; cc->aotc=&bound->aotc;
  cc->flags=cc->flags&~mask|CCF_AOT_COMPILE; cc->pass=0;
  I386FrontendCalls(state,bound,cc);
  out=I386OutNew(state->heap,cc);
  if(!out) throw('OutMem',TRUE);
  I386FrontendHelpers(bound,state->expression.types); cc->htc.hash_table_lst=&bound->helpers;
  if(!I386BackendCompileWithBreak(state->heap,cc,state->expression.types,out,&bound->status,&I386ExecutionBreakPoll)) I386FrontendUnavailable(state);
  for(metadata=bound->aot.next_ie;metadata!=&bound->aot.next_ie;metadata=metadata->next)
    if(metadata->type!=IET_I386_DATA) I386FrontendUnavailable(state);
  result=I386FrontendAlloc(state,sizeof(CI386FrontendCode),TRUE,FALSE);
  result->code=I386ParserCodeAlloc(state->heap,cc,out->count); result->bytes=out->count;
  if(!result->code) I386FrontendUnavailable(state);
  result->value_class=type; result->raw_type=type->raw_type; result->prior_misc=prior_misc;
  result->data_start=out->count;
  for(metadata=bound->aot.next_ie;metadata!=&bound->aot.next_ie;metadata=metadata->next) {
    if(metadata->rip<0 || metadata->rip>out->count || metadata->flags<0 || metadata->flags>out->count-metadata->rip)
      I386FrontendUnavailable(state);
    if(metadata->rip<result->data_start) result->data_start=metadata->rip;
  }
  for(i=0;i<out->count;i++) result->code[i]=out->data[i];
  I386FrontendLink(state,bound,result);
  result->next=state->codes; state->codes=result;
  if(!I386OutDel(state->heap,cc,out) || !I386COCDiscard(state->heap,cc)) I386FrontendUnavailable(state);
  cc->aot=old_aot; cc->aotc=old_aotc; cc->htc.hash_table_lst=old_hash;
  cc->flags=cc->flags&~mask|old_flags&mask; cc->pass=old_pass;
  I386FrontendFree(state,bound); return result;
}
U8 *I386FrontendCompile(U8 *context,CCmpCtrl *cc,I64 *raw_type)
{
  CI386Frontend *state=context;
  CI386FrontendBound *bound;
  CI386FrontendCode *result=0;
  CIntermediateCode *ret,*node;
  CHashClass *type;
  CHashFun *old_fun=cc->htc.fun;
  CAOT *old_aot=cc->aot;
  CAOTCtrl *old_aotc=cc->aotc;
  CHashTable *old_hash=cc->htc.hash_table_lst;
  CI386Out *out;
  CAOTImportExport *metadata;
  I64 old_flags=cc->flags,old_pass=cc->pass,i;
  I64 mask=CCF_DONT_MAKE_RES|CCF_AOT_COMPILE|CCF_EXE_BLK|CCF_TARGET_HOST_CONST|1<<CCf_PASS_TRACE_PRESENT;
  if(cc!=state->cc || !I386CmpCodeOwner(state->heap,cc)) I386FrontendUnavailable(state);
  bound=I386FrontendAlloc(context,sizeof(CI386FrontendBound),TRUE,FALSE);
  I386FrontendPush(state,cc); I386FrontendInit(state,cc);
  bound->fun.return_class=state->expression.types[RT_I64];
  bound->aot.next_ie=bound->aot.last_ie=&bound->aot.next_ie;
  bound->typer.types=state->expression.types;
  cc->htc.fun=&bound->fun; cc->aot=&bound->aot; cc->aotc=&bound->aotc;
  cc->flags=cc->flags&~mask|old_flags&CCF_AOT_COMPILE; cc->pass=0;
  I386FrontendAdd(state,cc,IC_ENTER,0,0,0);
  if(I386FrontendExpression(state,cc,0,FALSE,0)) {
    for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next)
      if(node->ic_code==IC_RBP) I386FrontendUnavailable(state);
    ret=I386FrontendAdd(state,cc,IC_RETURN_VAL,0,state->expression.types[RT_I64],0);
    I386FrontendAdd(state,cc,IC_LEAVE,0,0,0);
    I386FrontendOptimize(state,cc);
    if(!ret->t.arg1_tree || !(type=I386ValueClass(&bound->typer,ret->t.arg1_tree)))
      I386FrontendUnavailable(state);
    ret->ic_class=bound->fun.return_class=type;
    result=I386FrontendOutput(state,cc,type,old_flags&CCF_HAS_MISC_DATA);
    if(raw_type) *raw_type=type->raw_type;
  }
  if(!I386COCDiscard(state->heap,cc)) I386FrontendUnavailable(state);
  I386FrontendPop(state,cc);
  cc->htc.fun=old_fun; cc->aot=old_aot; cc->aotc=old_aotc; cc->htc.hash_table_lst=old_hash;
  cc->flags=cc->flags&~mask|old_flags&mask; cc->pass=old_pass;
  I386FrontendFree(state,bound);
  if(result) return result->code;
  return 0;
}
I64 I386FrontendExecute(U8 *context,U8 *code)
{
  CI386Frontend *state=context;
  CI386FrontendCode *record;
  I64 (*entry)(),value;
  U64 base;
  if(!I386CmpCodeOwner(state->heap,state->cc)) I386FrontendUnavailable(state);
  for(record=state->codes;record;record=record->next)
    if(record->code==code) {
      entry=code; value=(*entry)(); base=(code+0)(U64);
      //A numeric result may have used literal data while computing its value.
      //Only a returned address into this output needs the default-string copy.
      state->cc->flags=state->cc->flags&~CCF_HAS_MISC_DATA|record->prior_misc;
      if(record->raw_type!=RT_F64 && value(U64)>=base+record->data_start && value(U64)<base+record->bytes)
        state->cc->flags|=CCF_HAS_MISC_DATA;
      return value;
    }
  I386FrontendUnavailable(state); return 0;
}
I64 I386FrontendInteger(U8 *context,CCmpCtrl *cc)
{
  U8 *code;
  I64 raw_type,result;
  code=I386FrontendCompile(context,cc,&raw_type);
  if(!code) I386FrontendUnavailable(context);
  result=I386FrontendExecute(context,code);
  if(raw_type==RT_F64) result=I386F64ToI64(result);
  I386FrontendFree(context,code); return result;
}
I64 I386FrontendEvaluate(U8 *context,CCmpCtrl *cc)
{
  U8 *code=I386FrontendCompile(context,cc,0);
  I64 result;
  if(!code) I386FrontendUnavailable(context);
  result=I386FrontendExecute(context,code);
  I386FrontendFree(context,code); return result;
}
extern U0 I386FrontendSource(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol,I64 adjust);
I64 I386FrontendDirective(U8 *context,CCmpCtrl *cc,I64 keyword)
{
  CI386Frontend *state=context;
  CHashSrcSym *symbol;
  U8 *name;
  U32 irq;
  if(keyword==KW_HELP_FILE) {
    if(I386FrontendLex(context,cc)!=TK_STR) return cc->token;
    if(!state->files || !state->files->name_abs) I386FrontendUnavailable(context);
    symbol=I386FrontendAlloc(context,sizeof(CHashSrcSym),TRUE,FALSE);
    name=state->files->name_abs(state->heap,cc->cur_str,"DD.Z");
    if(!name) throw('OutMem',TRUE);
    if(!I386ParserTake(state->heap,cc,name)) {
      irq=I386IrqSave; I386HeapFree(state->heap,name); I386IrqRestore(irq);
      throw('OutMem',TRUE);
    }
    symbol->str=name; symbol->type=HTT_HELP_FILE|HTF_PUBLIC;
    I386FrontendSource(context,cc,symbol,0);
    HashAdd(symbol,state->table);
    return I386FrontendLex(context,cc);
  }
  if(keyword!=KW_ASSERT) I386FrontendUnavailable(context);
  if(!I386FrontendLex(context,cc)) return TK_EOF;
  if(!I386FrontendEvaluate(context,cc)) I386FrontendReport(context,cc,1,"Assert Failed ");
  return cc->token;
}
CHashClass *I386FrontendClassNew(U8 *context)
{
  CHashClass *type=I386FrontendAlloc(context,sizeof(CHashClass)*(PTR_STARS_NUM+1),TRUE,FALSE);
  PrsClassInit(type); return type;
}
CHashFun *I386FrontendFunNew(U8 *context)
{
  CHashFun *fun=I386FrontendAlloc(context,sizeof(CHashFun)*(PTR_STARS_NUM+1),TRUE,FALSE);
  PrsFunInit(fun); return fun;
}
CHash *I386FrontendSingleFind(U8 *context,U8 *name,CHashTable *table,I64 mask)
{
  CHash *entry;
  I64 i;
  for(i=0;i<=table->mask;i++)
    for(entry=table->body[i];entry;entry=entry->next)
      if(entry->type&mask && !StrCmp(entry->str,name)) return entry;
  return 0;
}
#include "/Compiler/I386/FrontendClassCompletion.HC"
CHashClass *I386FrontendClass(U8 *context,CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern)
{
  CI386Frontend *state=context;
  CHashClass *result;
  //Published descriptors remain unchanged until the whole input commits.
  result=HashFind(cc->cur_str,state->parent,HTT_CLASS);
  if(result && Bt(&result->flags,Cf_EXTERN) &&
      !I386FrontendSingleFind(state,cc->cur_str,state->table,HTT_CLASS)) {
    if(is_extern) { I386FrontendLex(state,cc); return result; }
    I386FrontendStageClass(state,result);
  }
  if(!is_extern) {
    result=I386FrontendSingleFind(state,cc->cur_str,state->table,HTT_CLASS);
    if(result && Bt(&result->flags,Cf_EXTERN)) I386CompletionCheckPriorValues(state,result);
  }
  result=I386ParseClass(state->heap,cc,&state->symbols,keyword,flags,is_extern);
  if(!result) I386FrontendUnavailable(state);
  return result;
}
CHashFun *I386FrontendFun(U8 *context,CCmpCtrl *cc,CHashClass *type,U8 *name,I64 flags)
{
  CI386Frontend *state=context;
  if(name && HashFind(name,state->parent,HTT_FUN)) I386FrontendUnavailable(state);
  return I386ParseFunJoin(state->heap,cc,&state->symbols,type,name,flags);
}
U0 I386FrontendClassMembers(U8 *context,CHashClass *type)
{
  CSymbolRelease owner;
  owner.context=context; owner.release=&I386FrontendFree;
  SymbolClassMemberLstDel(&owner,type);
}
U0 I386FrontendMembers(U8 *context,CMemberLst *members)
{
  CSymbolRelease owner;
  owner.context=context; owner.release=&I386FrontendFree;
  SymbolMemberLstDel(&owner,members);
}
U0 I386FrontendSource(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol,I64 adjust)
{
  U8 *name=cc->lex_include_stk->full_name,*link;
  I64 line=cc->lex_include_stk->line_num+adjust,n,digits=1,length=StrLen(name),i;
  if(line<1) line=1;
  n=line; while(n>=10) { digits++; n/=10; }
  I386FrontendFree(context,symbol->src_link); symbol->src_link=0;
  link=I386FrontendAlloc(context,length+digits+5,FALSE,FALSE);
  link[0]='F'; link[1]='L'; link[2]=':';
  for(i=0;i<length;i++) link[i+3]=name[i];
  link[length+3]=','; link[length+digits+4]=0;
  n=line;
  for(i=length+digits+3;i>=length+4;i--) { link[i]='0'+n%10; n/=10; }
  symbol->src_link=link;
  if(Bt(&cc->opts,OPTf_KEEP_PRIVATE)) symbol->type|=HTF_PRIVATE;
  I386FrontendFree(context,symbol->idx); symbol->idx=0;
  if(cc->cur_help_idx && *cc->cur_help_idx) symbol->idx=I386FrontendDuplicate(context,cc->cur_help_idx);
}
Bool I386FrontendOption(U8 *context,I64 index)
{
  CI386Frontend *state=context;
  return Bt(&state->cc->opts,index);
}
U0 I386FrontendWarning(U8 *context,CCmpCtrl *cc,I64 kind,CHashSrcSym *symbol)
{ cc->warning_cnt++; }
I64 I386FrontendDefine(U8 *context,U8 *name,U8 *list)
{
  if(StrCmp(list,"ST_U64_REGS")) I386FrontendUnavailable(context);
  //Automatic register hints may fall back to stack slots. Explicit machine
  //register assignments need their own target policy before this JIT accepts them.
  if(name[0]=='R' && (name[1]>='0' && name[1]<='9' ||
      !StrCmp(name,"RAX") || !StrCmp(name,"RBX") || !StrCmp(name,"RCX") || !StrCmp(name,"RDX") ||
      !StrCmp(name,"RSP") || !StrCmp(name,"RBP") || !StrCmp(name,"RSI") || !StrCmp(name,"RDI")))
    I386FrontendUnavailable(context);
  return -1;
}
U0 I386FrontendInitialize(U8 *context,U8 *data,I64 bytes)
{
  I64 i;
  if(bytes<0 || !data && bytes) I386FrontendUnavailable(context);
  for(i=0;i<bytes;i++) data[i]=0;
}
U0 I386FrontendStatic(U8 *context,CCmpCtrl *cc,CMemberLst *member,I64 pass)
{
  CI386Frontend *state=context;
  if(cc->flags&CCF_AOT_COMPILE) I386FrontendUnavailable(state);
  PrsStaticInitCore(&state->initializers,cc,member,pass);
}
U0 I386FrontendStore(U8 *context,CCmpCtrl *cc,I64 value)
{ I386FrontendUnavailable(context); }
U0 I386FrontendStoreAt(U8 *context,CCmpCtrl *cc,I64 address,U8 value)
{ I386FrontendUnavailable(context); }
U0 I386FrontendRange(U8 *context,CCmpCtrl *cc,I64 address,I64 bytes)
{ if(cc->flags&CCF_AOT_COMPILE) I386FrontendUnavailable(context); }
CI386Frontend *I386FrontendNew(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386LexIncludeService *includes)
{
  CI386Frontend *state;
  CPrsExpressionServices *e;
  CPrsTypeServices *t;
  CPrsDeclarationServices *d;
  CPrsSymbolServices *s;
  if(!I386CmpCodeOwner(heap,cc) || !types || !types[RT_I64] || !types[RT_U64] || !types[RT_F64]) return 0;
  state=I386ParserAlloc(heap,cc,sizeof(CI386Frontend),TRUE);
  if(!state) return 0;
  state->heap=heap; state->cc=cc; state->parent=cc->htc.glbl_hash_table;
  if(includes) { state->lex_services.context=includes->context; state->lex_services.push=includes->push; }
  state->lex_services.directive_context=state; state->lex_services.directive=&I386FrontendDirective;
  state->includes=&state->lex_services;
  state->table=I386FrontendAlloc(state,sizeof(CHashTable),TRUE,FALSE);
  state->table->body=I386FrontendAlloc(state,32*sizeof(CHash *),TRUE,FALSE);
  state->table->mask=31; state->table->next=state->parent;
  cc->htc.glbl_hash_table=cc->htc.local_hash_table=cc->htc.hash_table_lst=state->table;
  PrsBinaryInit(state->binary_ops);
  e=&state->expression; e->context=state; e->types=types; e->binary_ops=state->binary_ops;
  e->lex=&I386FrontendLex; e->report=&I386FrontendReport; e->add=&I386FrontendAdd;
  e->retire=&I386FrontendRetire; e->misc=&I386FrontendMisc; e->init=&I386FrontendInit;
  e->push=&I386FrontendPush; e->pop=&I386FrontendPop; e->append=&I386FrontendAppend;
  e->optimize=&I386FrontendOptimize; e->allocate=&I386FrontendAlloc; e->duplicate=&I386FrontendDuplicate;
  e->string=&I386FrontendString; e->hash_add=&I386FrontendHashAdd; e->hash_after=&I386FrontendHashAfter;
  e->class_view=&I386FrontendClassView;
  e->retain_function_addresses=TRUE;
  e->type=&I386FrontendType; e->expression=&I386FrontendExpression;
  t=&state->types; t->context=state; t->types=types; t->lex=&I386FrontendLex; t->report=&I386FrontendReport;
  t->snapshot_push=&I386FrontendSnapshot; t->snapshot_drop=&I386FrontendDrop;
  t->integer_expression=&I386FrontendInteger; t->class_join=&I386FrontendClass; t->fun_join=&I386FrontendFun;
  t->allocate=&I386FrontendTypeAlloc; t->duplicate=&I386FrontendDuplicate;
  t->member_new=&I386FrontendMember; t->member_add=&I386FrontendMemberAdd;
  d=&state->declarations; d->context=state; d->expression=e; d->types=t;
  d->define_match=&I386FrontendDefine; d->evaluate=&I386FrontendEvaluate; d->snapshot_restore=&I386FrontendRestore;
  d->initialize_static=&I386FrontendInitialize; d->static_init=&I386FrontendStatic;
  d->store_u64=&I386FrontendStore; d->store_u8_at=&I386FrontendStoreAt; d->data_range=&I386FrontendRange;
  d->compile_expression=&I386FrontendCompile; d->execute=&I386FrontendExecute; d->release=&I386FrontendFree;
  s=&state->symbols; s->context=state; s->declarations=d; s->undefined_function=&I386FrontendUndefined;
  s->used_mask=REGG_CLOBBERED+REGG_SAVED+REGG_STK_TMP;
  s->clobbered_mask=REGG_CLOBBERED+REGG_STK_TMP;
  s->class_new=&I386FrontendClassNew; s->fun_new=&I386FrontendFunNew; s->single_find=&I386FrontendSingleFind;
  s->class_members_delete=&I386FrontendClassMembers; s->members_delete=&I386FrontendMembers;
  s->source=&I386FrontendSource; s->option=&I386FrontendOption; s->warning=&I386FrontendWarning;
  I386FrontendStatementsInit(state);
  cc->aotc=I386FrontendAlloc(state,sizeof(CAOTCtrl),TRUE,FALSE);
  return state;
}
Bool I386ScalarSchema(CHashClass *type,I64 raw,I64 size,I64 count)
{
  CHashClass *value;
  CMemberLst *member;
  U8 *name;
  I64 i=0,member_raw;
  if(!type || !(value=type->fwd_class) || value->ptr_stars_cnt || value->raw_type!=raw ||
      value->size!=size || type->size!=size || type->member_cnt!=count) return FALSE;
  for(member=type->member_lst_and_root;member;member=member->next) {
    name="i8"; member_raw=RT_I8;
    switch(i) {
      case 1: name="u8"; member_raw=RT_U8; break;
      case 2: name="i16"; member_raw=RT_I16; break;
      case 3: name="u16"; member_raw=RT_U16; break;
      case 4: name="i32"; member_raw=RT_I32; break;
      case 5: name="u32"; member_raw=RT_U32; break;
      default: if(i) return FALSE;
    }
    value=OptClassFwd(member->member_class);
    if(StrCmp(member->str,name) || member->offset || member->size!=size || value->ptr_stars_cnt ||
        value->raw_type!=member_raw || !member->dim.next || member->dim.next->next ||
        member->dim.total_cnt!=size/(1<<(i/2)) || member->dim.next->cnt!=member->dim.total_cnt) return FALSE;
    i++;
  }
  if(i!=count) return FALSE;
  for(i=1;i<=PTR_STARS_NUM;i++)
    if(type[i].ptr_stars_cnt!=i || type[i].size!=4 || type[i].raw_type!=RT_PTR) return FALSE;
  return TRUE;
}
Bool I386ScalarTypesCheck(CHashClass **roots,Bool record)
{
  CHashTable *table=I386TaskSelf->hash_table;
  CHashClass *found[6],*type;
  U8 *name="U16\0I16\0U32\0I32\0U64\0I64";
  I64 i,raw;
  if(!table || !roots) return FALSE;
  for(i=0;i<6;i++,name+=4) {
    raw=RT_U16;
    switch(i) {
      case 1: raw=RT_I16; break;
      case 2: raw=RT_U32; break;
      case 3: raw=RT_I32; break;
      case 4: raw=RT_U64; break;
      case 5: raw=RT_I64; break;
    }
    type=HashFind(name,table,HTT_CLASS);
    if(!I386ScalarSchema(type,raw,2<<(i/2),2+i/2*2) || !type->src_link || !type->idx ||
        StrCmp(type->idx,"Data Types/Simple") || !record && roots[i]!=type) return FALSE;
    found[i]=type;
  }
  if(record) for(i=0;i<6;i++) roots[i]=found[i];
  return TRUE;
}
Bool I386BootstrapScalars(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386LexIncludeService *includes)
{
  CI386CmpCtrl *owned=cc;
  CI386Frontend *state;
  CHashClass *first,*type;
  CArrayDim dim;
  U8 *name;
  I64 i,mode,size,count,raw;
  if(!I386CmpCodeOwner(heap,cc) || !owned->task || cc->htc.glbl_hash_table!=owned->task->hash_table ||
      !(cc->flags&CCF_AOT_COMPILE) || cc->error_cnt || owned->code_next!=&owned->code_next) return FALSE;
  state=I386FrontendNew(heap,cc,types,includes);
  if(!state) return FALSE;
  I386FrontendLex(state,cc);
  //Bootstrap schema, not a replacement statement grammar: type/header/body parsing
  //is performed by the same cores that compile ordinary HolyC declarations.
  for(i=0;i<6;i++) {
    name="U16"; size=2; count=2; raw=RT_U16;
    switch(i) {
      case 1: name="I16"; raw=RT_I16; break;
      case 2: name="U32"; size=4; count=4; raw=RT_U32; break;
      case 3: name="I32"; size=4; count=4; raw=RT_I32; break;
      case 4: name="U64"; size=8; count=6; raw=RT_U64; break;
      case 5: name="I64"; size=8; count=6; raw=RT_I64; break;
    }
    if(cc->token!=TK_IDENT || !(first=cc->hash_entry) || !(first->type&HTT_INTERNAL_TYPE)) I386FrontendUnavailable(state);
    I386FrontendLex(state,cc);
    mode=PRS0_NULL|PRS1_NULL; dim.next=0; dim.cnt=0; dim.total_cnt=1;
    type=I386FrontendType(state,cc,&first,&mode,0,0,0,0,&dim,0);
    if(!I386ScalarSchema(type,raw,size,count) || StrCmp(type->str,name) || cc->token!=';' ||
        !type->src_link || !type->idx || StrCmp(type->idx,"Data Types/Simple"))
      I386FrontendUnavailable(state);
    I386FrontendLex(state,cc);
  }
  if(cc->token!=TK_EOF) I386FrontendUnavailable(state);
  return I386PublishClasses(heap,cc,state->table);
}

CPrsSymbolServices *I386FrontendServices(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386LexIncludeService *includes)
{
  CI386CmpCtrl *owned=cc;
  CI386Frontend *state;
  if(!I386CmpCodeOwner(heap,cc) || !owned->task || cc->htc.glbl_hash_table!=owned->task->hash_table ||
      !(cc->flags&CCF_AOT_COMPILE) || cc->error_cnt || owned->code_next!=&owned->code_next) return 0;
  state=I386FrontendNew(heap,cc,types,includes);
  if(!state) return 0;
  return &state->symbols;
}
