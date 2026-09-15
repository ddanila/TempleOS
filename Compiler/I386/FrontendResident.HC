//Native declarations borrow system exports; only their metadata is owned.
CI386FrontendResident *I386FrontendResidentFind(CI386Frontend *state,CHashSrcSym *declaration)
{
  CI386FrontendResident *binding;
  for(binding=state->residents;binding;binding=binding->next)
    if(binding->declaration==declaration) return binding;
  return 0;
}
Bool I386FrontendResidentValid(CI386Frontend *state,CI386FrontendResident *binding)
{
  CHashTable *table;
  CHash *entry;
  I64 i,address;
  if(!I386ParserRecord(state->cc,binding) ||
      I386HeapSize(state->heap,binding)!=sizeof(CI386FrontendResident) ||
      !I386ParserRecord(state->cc,binding->declaration)) return FALSE;
  if(binding->declaration->type&HTT_FUN) {
    address=(binding->declaration(CHashFun *)->exe_addr+0)(U64);
    if(!address) return FALSE;
  } else if(binding->declaration->type&HTT_GLBL_VAR &&
      binding->declaration(CHashGlblVar *)->flags&GVF_ALIAS)
    address=(binding->declaration(CHashGlblVar *)->data_addr+0)(U64);
  else return FALSE;
  if(address!=binding->address || address<0 || address>U32_MAX) return FALSE;
  for(table=state->parent;table;table=table->next)
    for(i=0;i<=table->mask;i++)
      for(entry=table->body[i];entry;entry=entry->next)
        if(entry==binding->export)
          return entry->type&HTT_EXPORT_SYS_SYM && binding->export->val==address;
  return FALSE;
}
U0 I386FrontendResidentBind(CI386Frontend *state,CHashSrcSym *declaration,I64 address)
{
  CI386FrontendResident *binding=I386FrontendResidentFind(state,declaration);
  CHashTable *table;
  CHash *entry;
  I64 i;
  if(address<0 || address>U32_MAX || !I386ParserRecord(state->cc,declaration))
    I386FrontendUnavailable(state);
  if(binding) {
    if(!I386FrontendResidentValid(state,binding)) I386FrontendUnavailable(state);
    return;
  }
  for(table=state->parent;table;table=table->next)
    for(i=0;i<=table->mask;i++)
      for(entry=table->body[i];entry;entry=entry->next)
        if(entry->type&HTT_EXPORT_SYS_SYM && entry(CHashExport *)->val==address) {
          binding=I386FrontendAlloc(state,sizeof(CI386FrontendResident),TRUE,FALSE);
          binding->declaration=declaration; binding->export=entry; binding->address=address;
          binding->next=state->residents; state->residents=binding;
          return;
        }
  I386FrontendUnavailable(state);
}
Bool I386FrontendResidentCollision(CHashTable *table,U8 *name,CHashExport *allowed)
{
  CHash *entry;
  I64 i;
  for(i=0;i<=table->mask;i++)
    for(entry=table->body[i];entry;entry=entry->next)
      if(!StrCmp(entry->str,name) && entry!=allowed) return TRUE;
  return FALSE;
}
