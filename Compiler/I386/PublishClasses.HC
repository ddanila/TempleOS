//Included after parser memory and the shared nonmutating symbol ownership walk.
#include "/Compiler/I386/PublishClasses.HH"
class CI386ClassTransfer {
  CI386CmpCtrl *owned;
  CHashTable *source;
  CI386ParserAllocation **records;
  I64 count,capacity;
  Bool ok;
};
CI386ParserAllocation *I386ParserRecord(CI386CmpCtrl *owned,U8 *allocation)
{
  CI386ParserAllocation *record;
  for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
    if(record->allocation==allocation) return record;
  return 0;
}
U0 I386ClassTransferVisit(U8 *context,U8 *allocation)
{
  CI386ClassTransfer *state=context;
  CI386ParserAllocation *record;
  CCmpCtrl *cc=&state->owned->control;
  CLexFile *file;
  I64 i;
  if(!allocation || !state->ok) return;
  if(allocation==state->source || allocation==state->source->body ||
      allocation==cc->cur_str || allocation==cc->cur_help_idx ||
      allocation==cc->dollar_buf || allocation==cc->ps ||
      !(record=I386ParserRecord(state->owned,allocation)) || state->count>=state->capacity) {
    state->ok=FALSE; return;
  }
  for(file=cc->lex_include_stk;file;file=file->next)
    if(allocation==file || allocation==file->buf || allocation==file->full_name) { state->ok=FALSE; return; }
  for(i=0;i<state->count;i++) if(state->records[i]==record) { state->ok=FALSE; return; }
  state->records[state->count++]=record;
}
Bool I386ClassNamePresent(CHashTable *table,U8 *name)
{
  CHash *entry;
  I64 i;
  for(i=0;i<=table->mask;i++)
    for(entry=table->body[i];entry;entry=entry->next)
      if(!StrCmp(entry->str,name)) return TRUE;
  return FALSE;
}
Bool I386PublishClasses(CI386Heap *heap,CCmpCtrl *cc,CHashTable *source)
{
  CI386CmpCtrl *owned=cc;
  CI386ClassTransfer state;
  CSymbolRelease visitor;
  CI386ParserAllocation *record;
  CI386Task *task;
  CHashTable *destination;
  CHashClass *entry;
  I64 i,j,capacity=0;
  U32 irq=I386IrqSave;
  Bool result=FALSE;
  state.records=0;
  if(!I386CmpCodeOwner(heap,cc) || !(task=owned->task) || cc->error_cnt || cc->lex_prs_stk || cc->htc.next ||
      owned->code_next!=&owned->code_next || !source || source==task->hash_table ||
      cc->htc.glbl_hash_table!=source || cc->htc.hash_table_lst!=source ||
      !I386ParserRecord(owned,source) || I386HeapSize(heap,source)!=sizeof(CHashTable)) goto done;
  destination=task->hash_table;
  if(!I386HashTableValid(heap,destination) || destination->locked_flags || source->locked_flags ||
      source->next!=destination || source->mask<0 || source->mask>=0x1FFFFFFF ||
      (source->mask+1)&source->mask || !I386ParserRecord(owned,source->body) ||
      I386HeapSize(heap,source->body)!=(source->mask+1)*sizeof(CHash *)) goto done;
  for(record=owned->parser_next;record!=&owned->parser_next;record=record->next) capacity++;
  if(capacity<1 || capacity>0x1FFFFFFF) goto done;
  state.records=I386HeapAlloc(heap,capacity*sizeof(CI386ParserAllocation *),FALSE);
  if(!state.records) goto done;
  state.owned=owned; state.source=source; state.count=0; state.capacity=capacity; state.ok=TRUE;
  visitor.context=&state; visitor.release=&I386ClassTransferVisit;
  for(i=0;i<=source->mask;i++)
    for(entry=source->body[i];entry;entry=entry->next) {
      if(!(entry->type&HTT_CLASS) || entry->type&HTT_FUN || !entry->str ||
          !I386ParserRecord(owned,entry) ||
          I386HeapSize(heap,entry)!=sizeof(CHashClass)*(PTR_STARS_NUM+1) ||
          I386ClassNamePresent(destination,entry->str)) goto done;
      //Source names must also be unique; publishing must not silently shadow a sibling.
      for(j=0;j<=i;j++) {
        CHashClass *prior=source->body[j];
        while(prior && prior!=entry) {
          if(!StrCmp(prior->str,entry->str)) goto done;
          prior=prior->next;
        }
      }
      SymbolHashVisit(&visitor,entry);
      if(!state.ok) goto done;
    }
  //No allocation or fallible lookup remains. Move payload ownership, then roots.
  for(i=0;i<state.count;i++) {
    record=state.records[i];
    record->last->next=record->next; record->next->last=record->last;
    I386HeapFree(heap,record);
  }
  for(i=0;i<=source->mask;i++)
    while(entry=source->body[i]) {
      source->body[i]=entry->next; entry->next=0;
      HashAdd(entry,destination);
    }
  result=TRUE;
done:
  if(state.records) I386HeapFree(heap,state.records);
  I386IrqRestore(irq); return result;
}
