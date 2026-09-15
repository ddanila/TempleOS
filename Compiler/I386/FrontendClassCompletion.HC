//Private class completion. Public roots and pointer variants keep their addresses.
Bool I386ProgramTypeReady(CHashClass *type)
{
  if(!type) return FALSE;
  while(type->fwd_class) type=type->fwd_class;
  return type->ptr_stars_cnt || !Bt(&type->flags,Cf_EXTERN);
}
Bool I386ProgramClassReady(CHashClass *type)
{
  if(Bt(&type->flags,Cf_EXTERN))
    return !type->size && !type->neg_offset && !type->member_cnt &&
      !type->ptr_stars_cnt && type->raw_type==RT_PTR &&
      !type->member_lst_and_root && !type->member_class_base_root &&
      type->last_in_member_lst==&type->member_lst_and_root &&
      !type->base_class && !type->fwd_class &&
      !(type->type&(HTF_IMPORT|HTF_UNRESOLVED));
  return (!type->base_class || I386ProgramTypeReady(type->base_class)) &&
    (!type->fwd_class || I386ProgramTypeReady(type->fwd_class));
}
Bool I386CompletionTargetValid(CI386Frontend *state,CHashClass *type)
{
  I64 i;
  if(!type || type->type&HTT_FUN || !(type->type&HTT_CLASS) || !type->str ||
      !Bt(&type->flags,Cf_EXTERN) || !I386ProgramClassReady(type) ||
      type->import_name || type->ie_lst || type->dbg_info ||
      I386FrontendSingleFind(state,type->str,state->parent,HTT_CLASS)!=type ||
      I386HeapSize(state->heap,type)!=sizeof(CHashClass)*(PTR_STARS_NUM+1) ||
      I386HeapSize(state->heap,type->str)<=0 ||
      type->src_link && I386HeapSize(state->heap,type->src_link)<=0 ||
      type->idx && I386HeapSize(state->heap,type->idx)<=0) return FALSE;
  for(i=1;i<=PTR_STARS_NUM;i++)
    if(type[i].ptr_stars_cnt!=i || type[i].size!=4 || type[i].raw_type!=RT_PTR ||
        type[i].member_lst_and_root || type[i].base_class || type[i].fwd_class) return FALSE;
  return TRUE;
}
Bool I386CompletionValueType(CHashClass *type,CHashClass *target)
{ return type && !type->ptr_stars_cnt && OptClassFwd(type)==target; }
U0 I386CompletionCheckValues(CI386Frontend *state,CHashSrcSym *entry,CHashClass *target)
{
  CHashClass *type;
  CHashGlblVar *global;
  CMemberLst *member;
  if(entry->type&HTT_FUN && Bt(&entry(CHashFun *)->flags,Cf_EXTERN) && state->cc->htc.fun!=entry)
    return; //An inactive forward/callback signature has not laid out an object.
  if(entry->type&(HTT_CLASS|HTT_FUN)) {
    type=entry;
    if(I386CompletionValueType(type->base_class,target) ||
        entry->type&HTT_FUN && I386CompletionValueType(entry(CHashFun *)->return_class,target))
      I386FrontendUnavailable(state);
    for(member=type->member_lst_and_root;member;member=member->next) {
      if(I386CompletionValueType(member->member_class,target)) I386FrontendUnavailable(state);
      if(member->flags&MLF_FUN)
        I386CompletionCheckValues(state,member->fun_ptr-member->fun_ptr->ptr_stars_cnt,target);
    }
  } else if(entry->type&HTT_GLBL_VAR) {
    global=entry;
    if(I386CompletionValueType(global->var_class,target)) I386FrontendUnavailable(state);
    if(global->fun_ptr) I386CompletionCheckValues(state,global->fun_ptr-global->fun_ptr->ptr_stars_cnt,target);
  }
}
U0 I386CompletionCheckPriorValues(CI386Frontend *state,CHashClass *target)
{
  CHashSrcSym *entry;
  I64 i;
  //An object or base laid out while the type was empty cannot acquire the new
  //size retroactively. Reject before enabling member access or executing code.
  for(i=0;i<=state->table->mask;i++)
    for(entry=state->table->body[i];entry;entry=entry->next)
      I386CompletionCheckValues(state,entry,target);
}
U0 I386FrontendStageClass(CI386Frontend *state,CHashClass *published)
{
  CI386FrontendCompletion *completion;
  CHashClass *staged;
  if(!I386CompletionTargetValid(state,published)) I386FrontendUnavailable(state);
  I386CompletionCheckPriorValues(state,published);
  completion=I386FrontendAlloc(state,sizeof(CI386FrontendCompletion),TRUE,FALSE);
  staged=I386FrontendClassNew(state);
  //The name is borrowed from the stable root. Generated lastclass arguments may
  //retain its address, so neither parsing nor commit substitutes a temporary name.
  staged->str=published->str; staged->flags=published->flags;
  staged->use_cnt=published->use_cnt;
  staged->type=published->type;
  completion->published=published; completion->staged=staged;
  completion->next=state->completions; state->completions=completion;
  HashAdd(staged,state->table);
}
CI386FrontendCompletion *I386CompletionFind(CI386Frontend *state,CHashSrcSym *entry)
{
  CI386FrontendCompletion *completion;
  for(completion=state->completions;completion;completion=completion->next)
    if(completion->staged==entry) return completion;
  return 0;
}
Bool I386CompletionValid(CI386Frontend *state,CI386FrontendCompletion *completion)
{
  CHashClass *type=completion->staged;
  return I386ParserRecord(state->cc,completion) &&
    I386HeapSize(state->heap,completion)==sizeof(CI386FrontendCompletion) &&
    I386CompletionTargetValid(state,completion->published) &&
    I386ParserRecord(state->cc,type) &&
    I386HeapSize(state->heap,type)==sizeof(CHashClass)*(PTR_STARS_NUM+1) &&
    !Bt(&type->flags,Cf_EXTERN) && !type->import_name && !type->dbg_info &&
    type->str==completion->published->str &&
    I386FrontendSingleFind(state,type->str,state->table,HTT_CLASS)==type;
}
class CI386CompletionTransfer {
  CI386ClassTransfer *transfer;
  CI386FrontendCompletion *completion;
};
U0 I386CompletionVisit(U8 *context,U8 *allocation)
{
  CI386CompletionTransfer *visit=context;
  if(visit->completion && (allocation==visit->completion->staged ||
      allocation==visit->completion->published->str)) return;
  I386ClassTransferVisit(visit->transfer,allocation);
}
CHashClass *I386CompletionCanonical(CI386Frontend *state,CHashClass *type)
{
  CI386FrontendCompletion *completion;
  CHashClass *base;
  if(!type || !(type->type&HTT_CLASS)) return type;
  base=type-type->ptr_stars_cnt;
  for(completion=state->completions;completion;completion=completion->next)
    if(base==completion->staged) return completion->published+type->ptr_stars_cnt;
  return type;
}
U0 I386CompletionRebind(CI386Frontend *state,CHashSrcSym *entry)
{
  CHashClass *type;
  CHashFun *fun;
  CHashGlblVar *global;
  CMemberLst *member,**link,*prior;
  I64 i;
  if(entry->type&(HTT_CLASS|HTT_FUN)) {
    type=entry;
    type->member_class_base_root=0;
    for(member=type->member_lst_and_root;member;member=member->next) {
      member->member_class=I386CompletionCanonical(state,member->member_class);
      member->member_class_base=I386CompletionCanonical(state,member->member_class_base);
      member->left_class_base=member->right_class_base=0;
      //Changing type addresses changes the ordering of the local-type index.
      if(member->member_class_base) {
        link=&type->member_class_base_root;
        while(prior=*link) {
          if(member->member_class_base<prior->member_class_base) link=&prior->left_class_base;
          else if(member->member_class_base>prior->member_class_base) link=&prior->right_class_base;
          else { link=0; break; }
        }
        if(link) *link=member;
      }
      if(member->flags&MLF_FUN)
        I386CompletionRebind(state,member->fun_ptr-member->fun_ptr->ptr_stars_cnt);
    }
    for(i=0;i<=PTR_STARS_NUM;i++) {
      type->base_class=I386CompletionCanonical(state,type->base_class);
      type->fwd_class=I386CompletionCanonical(state,type->fwd_class);
      if(entry->type&HTT_FUN) {
        fun=type;
        fun->return_class=I386CompletionCanonical(state,fun->return_class);
        type=fun+1;
      } else type++;
    }
  } else if(entry->type&HTT_GLBL_VAR) {
    global=entry;
    global->var_class=I386CompletionCanonical(state,global->var_class);
    if(global->fun_ptr) I386CompletionRebind(state,global->fun_ptr-global->fun_ptr->ptr_stars_cnt);
  }
}
U0 I386CompletionCommit(CI386Frontend *state,CI386FrontendCompletion *completion)
{
  CHashClass *published=completion->published,*staged=completion->staged;
  U8 *destination=published,*source=staged;
  I64 i;
  //The target's hash link, name and use count remain live. New source metadata
  //and members have already passed the ownership transfer validation.
  if(published->src_link) I386HeapFree(state->heap,published->src_link);
  if(published->idx) I386HeapFree(state->heap,published->idx);
  published->src_link=staged->src_link; published->idx=staged->idx;
  published->type=staged->type;
  for(i=offset(CHashClass.size);i<sizeof(CHashClass)*(PTR_STARS_NUM+1);i++)
    destination[i]=source[i];
  if(published->last_in_member_lst==&staged->member_lst_and_root)
    published->last_in_member_lst=&published->member_lst_and_root;
}
