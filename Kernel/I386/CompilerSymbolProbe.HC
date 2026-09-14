//Parse the packaged public scalar unions through native class/type/declaration cores.
#include "/Kernel/I386/Bits.HH"
class CProbeSymbols {
  CProbeDeclarations declaration;
  CPrsSymbolServices symbols;
  CHashTable *table;
  CHashClass *scalars[6];
  I64 sources;
};
CHashClass *ProbeSymbolClass(U8 *context)
{
  CHashClass *type=ProbeDeclarationAllocate(context,sizeof(CHashClass)*(PTR_STARS_NUM+1),TRUE,FALSE);
  PrsClassInit(type); return type;
}
CHashFun *ProbeSymbolFun(U8 *context)
{
  CHashFun *fun=ProbeDeclarationAllocate(context,sizeof(CHashFun)*(PTR_STARS_NUM+1),TRUE,FALSE);
  PrsFunInit(fun); return fun;
}
U0 ProbeSymbolAdd(U8 *context,CHash *entry,CHashTable *table)
{
  CProbeSymbols *state=context;
  if(table!=state->table) KernelStop;
  HashAdd(entry,table);
}
CHash *ProbeSymbolFind(U8 *context,U8 *name,CHashTable *table,I64 mask)
{
  I64 i;
  CHash *entry;
  for(i=0;i<=table->mask;i++)
    for(entry=table->body[i];entry;entry=entry->next)
      if(entry->type&mask && !StrCmp(entry->str,name)) return entry;
  return 0;
}
U0 ProbeSymbolSource(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol,I64 adjust)
{
  CProbeSymbols *state=context;
  state->sources++;
  if(cc->cur_help_idx) symbol->idx=ProbeDeclarationDuplicate(context,cc->cur_help_idx);
}
Bool ProbeSymbolOption(U8 *context,I64 index) { return FALSE; }
U0 ProbeSymbolWarning(U8 *context,CCmpCtrl *cc,I64 kind,CHashSrcSym *symbol)
{ cc->warning_cnt++; }
CHashClass *ProbeSymbolJoin(U8 *context,CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern)
{
  CProbeSymbols *state=context;
  CProbeExpression *expression=&state->declaration.expression;
  CHashClass *result=expression->probe->compiler->parse_class(expression->heap,cc,&state->symbols,keyword,flags,is_extern);
  if(!result) KernelStop;
  return result;
}
CHashFun *ProbeSymbolFunJoin(U8 *context,CCmpCtrl *cc,CHashClass *return_type,U8 *name,I64 flags)
{
  CProbeSymbols *state=context;
  CProbeExpression *expression=&state->declaration.expression;
  CHashFun *result=expression->probe->compiler->parse_fun_join(expression->heap,cc,&state->symbols,return_type,name,flags);
  if(!result) KernelStop;
  return result;
}
U0 ProbeScalarUnions(CProbeSymbols *state,CCmpCtrl *cc)
{
  CProbeExpression *expression=&state->declaration.expression;
  CHashClass *first,*result,*forward;
  CMemberLst *member;
  CArrayDim dim;
  U8 *name,*member_name,*source;
  I64 i,j,mode,size,count,actual,expected;
  for(i=0;i<6;i++) {
    name="U16"; size=2; count=2;
    switch(i) {
      case 1: name="I16"; break;
      case 2: name="U32"; size=4; count=4; break;
      case 3: name="I32"; size=4; count=4; break;
      case 4: name="U64"; size=8; count=6; break;
      case 5: name="I64"; size=8; count=6; break;
    }
    if(cc->token!=TK_IDENT || !(first=cc->hash_entry) || !(first->type&HTT_INTERNAL_TYPE)) KernelStop;
    forward=first;
    ProbeExpressionLex(state,cc);
    mode=PRS0_NULL|PRS1_NULL; dim.next=0; dim.cnt=0; dim.total_cnt=1;
    result=expression->probe->compiler->parse_type(expression->heap,cc,&expression->types,
      &first,&mode,0,0,0,0,&dim,0);
    KernelLog("SCALAR TYPE "); KernelHex(i); KernelLog(" "); KernelHex(cc->token);
    if(result) { KernelLog(" "); KernelHex(result->size); KernelLog(" "); KernelHex(result->member_cnt); }
    KernelLog("\n");
    if(!result || result!=first || result->fwd_class!=forward || result->size!=size ||
        result->member_cnt!=count || StrCmp(result->str,name) || cc->token!=';' ||
        !result->idx || StrCmp(result->idx,"Data Types/Simple") ||
        ProbeSymbolFind(state,name,state->table,HTT_CLASS)!=result) KernelStop;
    state->scalars[i]=result;
    j=0;
    for(member=result->member_lst_and_root;member;member=member->next) {
      member_name="i8";
      switch(j) {
        case 1: member_name="u8"; break;
        case 2: member_name="i16"; break;
        case 3: member_name="u16"; break;
        case 4: member_name="i32"; break;
        case 5: member_name="u32"; break;
      }
      if(StrCmp(member->str,member_name) || MemberFind(member_name,result)!=member ||
          j==0 && StrCmp(member->member_class->str,"I8i") ||
          j==1 && StrCmp(member->member_class->str,"U8i")) KernelStop;
      if(member->offset || member->size!=size || !member->dim.next || member->dim.next->next ||
          member->dim.total_cnt!=size/(1<<(j/2)) || member->dim.next->cnt!=member->dim.total_cnt) KernelStop;
      if(j==2 && member->member_class!=state->scalars[1] ||
          j==3 && member->member_class!=state->scalars[0] ||
          j==4 && member->member_class!=state->scalars[3] ||
          j==5 && member->member_class!=state->scalars[2]) KernelStop;
      j++;
    }
    if(j!=count) KernelStop;
    for(j=1;j<=PTR_STARS_NUM;j++)
      if(result[j].ptr_stars_cnt!=j || result[j].size!=4 || result[j].raw_type!=RT_PTR) KernelStop;
    ProbeExpressionLex(state,cc);
  }
  if(cc->token!=TK_EOF || state->sources!=6 || !cc->cur_help_idx ||
      StrCmp(cc->cur_help_idx,"Data Types/Simple")) KernelStop;
  for(i=0;i<8;i++) {
    source="sizeof(U64)+sizeof(U64 *)+0x100000001(U32);"; expected=13;
    switch(i) {
      case 1: source="0xFFFF(I16);"; expected=-1; break;
      case 2: source="0xFFFFFFFF(I32);"; expected=-1; break;
      case 3: source="0xFFFFFFFFFFFFFFFF(U64)>>63;"; expected=1; break;
      case 4: source="sizeof(U64.u32)+sizeof(U64.u16)+sizeof(U64.u8);"; expected=24; break;
      case 5: source="0x10001(U16);"; expected=1; break;
      case 6: source="0xFFFFFFFFFFFFFFFF(U64)/2;"; expected=0x7FFFFFFFFFFFFFFF; break;
      case 7: source="0xFFFFFFFFFFFFFFFF(I64)/2;"; expected=0; break;
    }
    if(!I386LexIncludeCopy(expression->heap,cc,"Probe/ScalarUse.HC",source,FALSE)) KernelStop;
    ProbeExpressionLex(state,cc);
    actual=ProbeDeclarationInteger(state,cc);
    KernelLog("SCALAR RESULT "); KernelHex(expression->probe->phase); KernelLog(" ");
    KernelHex(i); KernelLog(" "); KernelHex(actual); KernelLog("\n");
    if(actual!=expected || cc->token!=';') KernelStop;
    ProbeExpressionLex(state,cc);
    if(cc->token!=TK_EOF) KernelStop;
  }
}
U0 ProbeSymbols(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CProbeSymbols *state;
  CPrsSymbolServices *services;
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CHashClass *first,*second;
  CHashFun *fun;
  U32 *binary_ops;
  U8 *source,*name,*fun_name;
  I64 kind,size,attr,accepted;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 irq,flags=GetRFlags;
  for(kind=0;kind<10;kind++) {
    KernelLog("SYMBOL START "); KernelHex(kind); KernelLog("\n");
    source="Base { U8 tag; } Child:Base { I64i value; }";
    switch(kind) {
      case 0:
        name=0; size=0; attr=0;
        source=probe->files->read(heap,"C:/Kernel/Types.HH",&size,&attr,&name);
        if(!source || !name || size<1) KernelStop;
        irq=I386IrqSave; I386HeapFree(heap,name); I386IrqRestore(irq);
        break;
      case 2: source="Broken { U8 good; Missing bad; }"; break;
      case 3: source="Broken { U8 same; U8 same; }"; break;
      case 4: source="#help_index \"Forward types\" Forward Forward { U8 data; }"; break;
      case 5: source="Sum(I64i a,U8 *b)"; break;
      case 6: source="Broken(I64i good,Missing bad)"; break;
      case 8: source="#help_index \"Old\" #help_index \"unterminated"; break;
      case 9: source="#help_index \"Old\" #help_index \"Data Types/Simple\" One { U8 n; }"; break;
      case 7: source="#help_index \"Data\"\\\" Types\"\\\"/Simple\" One { U8 n; }"; break;
    }
    size=CCF_AOT_COMPILE;
    if(kind) size|=CCF_DONT_FREE_BUF;
    cc=probe->files->control_new(source,size,"Probe/Symbols.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    state=probe->compiler->parser_alloc(heap,cc,sizeof(CProbeSymbols),TRUE);
    binary_ops=probe->compiler->parser_alloc(heap,cc,TK_TKS_NUM*sizeof(U32),TRUE);
    if(!state || !binary_ops) KernelStop;
    ProbeDeclarationSetup(&state->declaration,probe,heap,cc,binary_ops);
    state->table=ProbeDeclarationAllocate(state,sizeof(CHashTable),TRUE,FALSE);
    state->table->body=ProbeDeclarationAllocate(state,16*sizeof(CHash *),TRUE,FALSE);
    state->table->mask=15; state->table->next=cc->htc.hash_table_lst;
    cc->htc.glbl_hash_table=cc->htc.local_hash_table=cc->htc.hash_table_lst=state->table;
    state->declaration.expression.services.hash_add=&ProbeSymbolAdd;
    state->declaration.expression.types.class_join=&ProbeSymbolJoin;
    state->declaration.expression.types.fun_join=&ProbeSymbolFunJoin;
    services=&state->symbols; services->context=state; services->declarations=&state->declaration.declarations;
    services->class_new=&ProbeSymbolClass; services->fun_new=&ProbeSymbolFun;
    services->single_find=&ProbeSymbolFind; services->source=&ProbeSymbolSource;
    services->option=&ProbeSymbolOption; services->warning=&ProbeSymbolWarning;
    services->class_members_delete=&ProbeExpressionUnexpected; services->members_delete=&ProbeExpressionUnexpected;
    cc->aotc=ProbeDeclarationAllocate(state,sizeof(CAOTCtrl),TRUE,FALSE);
    accepted=0;
    try {
      ProbeExpressionLex(state,cc);
      KernelLog("SYMBOL TOKEN "); KernelHex(cc->token); KernelLog("\n");
      if(kind==0) ProbeScalarUnions(state,cc);
      else if(kind==5 || kind==6) {
        fun_name=cc->cur_str; cc->cur_str=0; ProbeExpressionLex(state,cc);
        fun=ProbeSymbolFunJoin(state,cc,probe->i64_type,fun_name,FSF_PUBLIC);
        if(kind==6 || !(fun->type&HTF_PUBLIC) || fun->arg_cnt!=2 || fun->size || cc->token!=TK_EOF ||
            fun->member_lst_and_root->offset!=8 || fun->last_in_member_lst->offset!=16 ||
            fun->return_class!=probe->i64_type || !fun->last_in_member_lst->member_class->ptr_stars_cnt) KernelStop;
      } else {
        first=ProbeSymbolJoin(state,cc,KW_CLASS,0,kind==4);
        if(kind==2 || kind==3 || kind==8) KernelStop;
        if(kind==1 || kind==4) {
          second=ProbeSymbolJoin(state,cc,KW_CLASS,0,FALSE);
          if(kind==1 && (first->size!=1 || second->base_class!=first || second->size!=9 ||
              second->member_lst_and_root->offset!=1)) KernelStop;
          if(kind==4 && (first!=second || second->size!=1 || Bt(&second->flags,Cf_EXTERN))) KernelStop;
        } else if(!first->idx || StrCmp(first->idx,"Data Types/Simple")) KernelStop;
        if(cc->token!=TK_EOF) KernelStop;
      }
      accepted=1;
    } catch {
      if(kind!=2 && kind!=3 && kind!=6 && kind!=8 || task->except_ch!='Compiler') {
        KernelLog("SYMBOL EXCEPTION "); KernelHex(kind); KernelLog(" "); KernelHex(task->except_ch); KernelLog("\n"); KernelStop;
      }
      task->catch_except=TRUE; accepted=1;
    }
    if(!accepted || !probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
        task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("SYMBOL CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
