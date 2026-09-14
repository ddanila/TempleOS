//Retained compiler environment. Private symbols and temporaries belong to one cc.
#include "/Compiler/I386/Frontend.HH"
#include "/Compiler/SymbolInit.HC"
#include "/Compiler/PrsBinary.HC"
#include "/Compiler/LexBackup.HC"
#include "/Compiler/I386/LexState.HC"
class CI386Frontend {
  CI386Heap *heap;
  CCmpCtrl *cc;
  CI386LexIncludeService *includes;
  CHashTable *table,*parent;
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsSymbolServices symbols;
  U32 binary_ops[TK_TKS_NUM];
  I64 lines;
};
class CI386FrontendBound {
  CHashFun fun;
  CAOT aot;
  CAOTCtrl aotc;
  CI386BackendStatus status;
};
U0 I386FrontendReport(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message)
{
  if(!kind) { cc->error_cnt++; throw('Compiler',TRUE); }
  if(kind!=2 || (cc->opts&1<<OPTf_WARN_PAREN) && !(cc->lex_include_stk->flags&LFSF_DEFINE)) cc->warning_cnt++;
}
U0 I386FrontendUnavailable(CI386Frontend *state)
{ I386FrontendReport(state,state->cc,0,"Native frontend service unavailable"); }
U8 *I386FrontendAlloc(U8 *context,I64 bytes,Bool zeroed,Bool code_heap)
{
  CI386Frontend *state=context;
  U8 *result=I386ParserAlloc(state->heap,state->cc,bytes,zeroed);
  if(!result) I386FrontendUnavailable(state);
  return result;
}
U8 *I386FrontendTypeAlloc(U8 *context,I64 bytes)
{ return I386FrontendAlloc(context,bytes,TRUE,FALSE); }
U0 I386FrontendFree(U8 *context,U8 *allocation)
{
  CI386Frontend *state=context;
  if(!I386ParserFree(state->heap,state->cc,allocation)) I386FrontendUnavailable(state);
}
U8 *I386FrontendDuplicate(U8 *context,U8 *source)
{
  I64 i,length=StrLen(source)+1;
  U8 *result=I386FrontendAlloc(context,length,FALSE,FALSE);
  for(i=0;i<length;i++) result[i]=source[i];
  return result;
}
I64 I386FrontendLex(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  return I386ParserToken(state->heap,cc,"Frontend",&state->lines,state->includes);
}
CIntermediateCode *I386FrontendAdd(U8 *context,CCmpCtrl *cc,I64 op,I64 value,CHashClass *type,I64 flags)
{
  CI386Frontend *state=context;
  CIntermediateCode *node=I386ICAdd(state->heap,cc,op,value,type,flags);
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
  CHashClass *result=I386ParseType(state->heap,cc,&state->types,first,mode,member,ident,fun,export_entry,dim,flags);
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
I64 I386FrontendInteger(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  CI386FrontendBound *bound=I386FrontendAlloc(context,sizeof(CI386FrontendBound),TRUE,FALSE);
  CHashFun *old_fun=cc->htc.fun;
  CAOT *old_aot=cc->aot;
  CAOTCtrl *old_aotc=cc->aotc;
  CI386Out *out;
  I64 old_flags=cc->flags,old_pass=cc->pass,result;
  I64 mask=CCF_DONT_MAKE_RES|CCF_AOT_COMPILE|CCF_EXE_BLK|CCF_TARGET_HOST_CONST;
  I64 (*code)();
  I386FrontendPush(state,cc); I386FrontendInit(state,cc);
  bound->fun.return_class=state->expression.types[RT_I64];
  bound->aot.next_ie=bound->aot.last_ie=&bound->aot.next_ie;
  cc->htc.fun=&bound->fun; cc->aot=&bound->aot; cc->aotc=&bound->aotc;
  cc->flags=cc->flags&~mask|CCF_AOT_COMPILE; cc->pass=0;
  I386FrontendAdd(state,cc,IC_ENTER,0,0,0);
  if(!I386FrontendExpression(state,cc,0,FALSE,0)) I386FrontendUnavailable(state);
  I386FrontendAdd(state,cc,IC_RETURN_VAL,0,state->expression.types[RT_I64],0);
  I386FrontendAdd(state,cc,IC_LEAVE,0,0,0);
  out=I386OutNew(state->heap,cc);
  if(!out) throw('OutMem',TRUE);
  if(!I386BackendCompile(state->heap,cc,state->expression.types,out,&bound->status)) I386FrontendUnavailable(state);
  code=out->data; result=(*code)();
  if(!I386OutDel(state->heap,cc,out) || !I386COCDiscard(state->heap,cc)) I386FrontendUnavailable(state);
  I386FrontendPop(state,cc);
  cc->htc.fun=old_fun; cc->aot=old_aot; cc->aotc=old_aotc;
  cc->flags=cc->flags&~mask|old_flags&mask; cc->pass=old_pass;
  I386FrontendFree(state,bound); return result;
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
CHashClass *I386FrontendClass(U8 *context,CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern)
{
  CI386Frontend *state=context;
  CHashClass *result;
  //The shared AOT join can complete an extern in a parent. Never mutate published graphs.
  result=HashFind(cc->cur_str,state->parent,HTT_CLASS);
  if(result && Bt(&result->flags,Cf_EXTERN)) I386FrontendUnavailable(state);
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
{ I386FrontendUnavailable(context); return -1; }
U0 I386FrontendInitialize(U8 *context,U8 *data,I64 bytes)
{ I386FrontendUnavailable(context); }
U0 I386FrontendStatic(U8 *context,CCmpCtrl *cc,CMemberLst *member,I64 pass)
{ I386FrontendUnavailable(context); }
U0 I386FrontendStore(U8 *context,CCmpCtrl *cc,I64 value)
{ I386FrontendUnavailable(context); }
U0 I386FrontendStoreAt(U8 *context,CCmpCtrl *cc,I64 address,U8 value)
{ I386FrontendUnavailable(context); }
U0 I386FrontendRange(U8 *context,CCmpCtrl *cc,I64 address,I64 bytes)
{ I386FrontendUnavailable(context); }
U8 *I386FrontendCompile(U8 *context,CCmpCtrl *cc,I64 *type)
{ I386FrontendUnavailable(context); return 0; }
I64 I386FrontendExecute(U8 *context,U8 *code)
{ I386FrontendUnavailable(context); return 0; }
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
  state->heap=heap; state->cc=cc; state->includes=includes; state->parent=cc->htc.glbl_hash_table;
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
  e->type=&I386FrontendType; e->expression=&I386FrontendExpression;
  t=&state->types; t->context=state; t->types=types; t->lex=&I386FrontendLex; t->report=&I386FrontendReport;
  t->snapshot_push=&I386FrontendSnapshot; t->snapshot_drop=&I386FrontendDrop;
  t->integer_expression=&I386FrontendInteger; t->class_join=&I386FrontendClass; t->fun_join=&I386FrontendFun;
  t->allocate=&I386FrontendTypeAlloc; t->duplicate=&I386FrontendDuplicate;
  t->member_new=&I386FrontendMember; t->member_add=&I386FrontendMemberAdd;
  d=&state->declarations; d->context=state; d->expression=e; d->types=t;
  d->define_match=&I386FrontendDefine; d->evaluate=&I386FrontendInteger; d->snapshot_restore=&I386FrontendRestore;
  d->initialize_static=&I386FrontendInitialize; d->static_init=&I386FrontendStatic;
  d->store_u64=&I386FrontendStore; d->store_u8_at=&I386FrontendStoreAt; d->data_range=&I386FrontendRange;
  d->compile_expression=&I386FrontendCompile; d->execute=&I386FrontendExecute; d->release=&I386FrontendFree;
  s=&state->symbols; s->context=state; s->declarations=d;
  s->used_mask=REGG_CLOBBERED+REGG_SAVED+REGG_STK_TMP;
  s->clobbered_mask=REGG_CLOBBERED+REGG_STK_TMP;
  s->class_new=&I386FrontendClassNew; s->fun_new=&I386FrontendFunNew; s->single_find=&I386FrontendSingleFind;
  s->class_members_delete=&I386FrontendClassMembers; s->members_delete=&I386FrontendMembers;
  s->source=&I386FrontendSource; s->option=&I386FrontendOption; s->warning=&I386FrontendWarning;
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
