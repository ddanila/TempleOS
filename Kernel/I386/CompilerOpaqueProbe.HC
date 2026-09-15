//Opaque dependencies own class metadata while their pointer users remain usable.
U0 ProbeOpaque(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskStorage *old_storage=scope->storage;
  CCmpCtrl *cc,*failed;
  CPrsSymbolServices *symbols,*failed_symbols;
  CHashSrcSym *roots[2],*entry;
  CHashClass *opaque,*holder;
  CMemberLst *member;
  U8 *source;
  I64 kind,i,count,before_used,before_allocations;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  Bool accepted,recovered;
  U32 flags=GetRFlags;
  for(kind=0;kind<7;kind++) {
    source="extern class Opaque;class Holder{Opaque *p;I64i value;};";
    if(kind==4) source="extern class Opaque;class Holder{Opaque value;};";
    if(kind==5) source="extern class Opaque;class Holder:Opaque{I64i value;};";
    if(kind==6) source="extern class Opaque;class Holder{Opaque *p;};class Opaque{I64i value;Holder link;};";
    KernelLog("OPAQUE START "); KernelHex(kind); KernelLog("\n");
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Opaque.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols || ProbeProgramRead(probe,heap,cc,symbols)) KernelStop;
    KernelLog("OPAQUE PARSED\n");
    opaque=ProbeSymbolFind(0,"Opaque",cc->htc.glbl_hash_table,HTT_CLASS);
    holder=ProbeSymbolFind(0,"Holder",cc->htc.glbl_hash_table,HTT_CLASS);
    if(!opaque || !holder) KernelStop;
    count=0;
    for(i=0;i<=cc->htc.glbl_hash_table->mask;i++)
      for(entry=cc->htc.glbl_hash_table->body[i];entry;entry=entry->next) {
        if(count>=2) KernelStop;
        roots[count++]=entry;
      }
    if(count!=2) KernelStop;
    KernelLog("OPAQUE SHAPE "); KernelHex(opaque->flags); KernelLog(" ");
    KernelHex(opaque->size); KernelLog(" "); KernelHex(holder->size); KernelLog(" ");
    KernelHex(opaque->last_in_member_lst==&opaque->member_lst_and_root); KernelLog("\n");
    if(kind==1) opaque->size=8;
    if(kind==2) opaque->base_class=probe->i64_type;
    if(kind==3) opaque->member_cnt=1;
    before_used=heap->used; before_allocations=heap->allocations;
    accepted=probe->compiler->publish(heap,cc,symbols);
    KernelLog("OPAQUE PUBLISHED "); KernelHex(accepted); KernelLog("\n");
    if(accepted!=(kind==0 || kind==6) || scope->storage!=old_storage) KernelStop;
    if(!accepted) {
      if(heap->used!=before_used || heap->allocations!=before_allocations) KernelStop;
      if(kind<4) {
        opaque->size=0; opaque->base_class=0; opaque->member_cnt=0;
        if(!probe->compiler->publish(heap,cc,symbols)) KernelStop;
        accepted=TRUE;
      }
    }
    if(!probe->compiler->control_unwind(task,outer)) KernelStop;
    KernelLog("OPAQUE UNWOUND\n");
    if(accepted) {
      member=holder->member_lst_and_root;
      if(!member || member->member_class!=opaque+1) KernelStop;
      KernelLog("OPAQUE IDENTITY\n");
      if(kind==6) {
        if(Bt(&opaque->flags,Cf_EXTERN) || opaque->size!=12 || holder->size!=4 ||
            ProbeProgramUse(probe,heap,outer,"Opaque x;x.value=42;x.link.p=&x;x.link.p->value;")!=42) KernelStop;
      } else {
        if(!Bt(&opaque->flags,Cf_EXTERN) || opaque->size || holder->size!=12 ||
            ProbeProgramUse(probe,heap,outer,"Holder x;x.p=0;x.value=42;x.value+(x.p!=0);")!=42) KernelStop;
        KernelLog("OPAQUE USED\n");
        if(kind==0) {
          //Until transactional completion exists, a new input must reject the
          //definition without changing the published class or its pointer users.
          failed=probe->files->control_new("class Opaque{I64i value;};",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/OpaqueFailure.HC");
          if(!failed || !probe->compiler->control_enter(heap,failed,0,0)) KernelStop;
          failed_symbols=probe->compiler->frontend(heap,failed,probe->internal_types,probe->disk_include);
          if(!failed_symbols) KernelStop;
          recovered=FALSE;
          try { ProbeProgramRead(probe,heap,failed,failed_symbols); }
          catch { if(task->except_ch=='Compiler') { task->catch_except=TRUE; recovered=TRUE; } }
          if(!recovered || probe->compiler->publish(heap,failed,failed_symbols) ||
              !probe->compiler->control_unwind(task,outer) || !Bt(&opaque->flags,Cf_EXTERN) ||
              opaque->size || opaque->member_lst_and_root || member->member_class!=opaque+1 ||
              ProbeProgramUse(probe,heap,outer,"sizeof(Holder);")!=12) KernelStop;
        }
      }
      for(i=0;i<count;i++)
        if(!ProbePublishedRemove(task->hash_table,roots[i]) || !I386HashDel(heap,roots[i])) KernelStop;
    }
    if(scope->storage!=old_storage || task->last_cc!=outer || task->active_controls!=1 ||
        task->lifetime_refs!=refs || task->except_top || heap->used!=used || heap->allocations!=allocations ||
        !I386HeapValid(heap) || (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("OPAQUE CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
