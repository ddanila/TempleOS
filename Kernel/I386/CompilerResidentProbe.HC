//Resident code/data are borrowed; publication owns only declaration metadata.
I64 ProbeResidentAdd(I64 value) { return value+2; }
U0 ProbeResidents(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskStorage *old_storage=scope->storage,*storage;
  CCmpCtrl *cc;
  CPrsSymbolServices *symbols;
  CHashExport service,catch_flag,collision;
  CHashSrcSym *roots[8],*entry;
  CHashFun *fun;
  CHashGlblVar *global;
  U8 *bytes,*source,*address;
  I64 kind,i,count,before_used,before_allocations;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  Bool old_answer=task->new_answer;
  U8 old_answer_type=task->answer_type;
  task->new_answer=TRUE; task->answer_type=0xA5;
  bytes=&service; for(i=0;i<sizeof(CHashExport);i++) bytes[i]=0;
  bytes=&catch_flag; for(i=0;i<sizeof(CHashExport);i++) bytes[i]=0;
  bytes=&collision; for(i=0;i<sizeof(CHashExport);i++) bytes[i]=0;
  service.str="ProbeResident"; service.type=HTT_EXPORT_SYS_SYM;
  service.val=(&ProbeResidentAdd+0)(U64);
  catch_flag.str="ProbeCatch"; catch_flag.type=HTT_EXPORT_SYS_SYM;
  catch_flag.val=(&task->catch_except+0)(U64);
  collision.str=service.str; collision.type=HTT_GLBL_VAR;
  HashAdd(&service,task->hash_table); HashAdd(&catch_flag,task->hash_table);
  for(kind=0;kind<7;kind++) {
    KernelLog("RESIDENT START "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
    source="extern I64i ProbeResident(I64i n);extern Bool ProbeCatch;"
      "extern U0 SysTry(U8i *caught,U8i *leave);extern U0 SysUntry();"
      "extern U0 throw(I64i ch=0,Bool no_log=0);"
      "I64i ResidentMain(){I64i n=0;try{n=ProbeResident(40);throw('Resident',1);}"
      "catch{if(n==42)ProbeCatch=1;}return n;}";
    if(kind==5) source="extern I64i ProbeResident(I64i n);";
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Resident.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols) KernelStop;
    ProbeProgramRead(probe,heap,cc,symbols);
    count=0;
    for(i=0;i<=cc->htc.glbl_hash_table->mask;i++)
      for(entry=cc->htc.glbl_hash_table->body[i];entry;entry=entry->next) {
        if(count>=8) KernelStop;
        roots[count++]=entry;
      }
    fun=ProbeSymbolFind(0,"ProbeResident",cc->htc.glbl_hash_table,HTT_FUN);
    global=ProbeSymbolFind(0,"ProbeCatch",cc->htc.glbl_hash_table,HTT_GLBL_VAR);
    if(!fun || (fun->exe_addr+0)(U64)!=service.val || kind!=5 &&
        (!global || !(global->flags&GVF_ALIAS) || (global->data_addr+0)(U64)!=catch_flag.val)) KernelStop;
    address=fun->exe_addr;
    if(kind==1) fun->exe_addr++;
    if(kind==2) service.val++;
    if(kind==3 && !ProbePublishedRemove(task->hash_table,&service)) KernelStop;
    if(kind==4) HashAdd(&collision,task->hash_table);
    if(kind==6) global->data_addr++;
    if(kind==1 || kind==2 || kind==3 || kind==4 || kind==6) {
      before_used=heap->used; before_allocations=heap->allocations;
      if(probe->compiler->publish(heap,cc,symbols) || heap->used!=before_used ||
          heap->allocations!=before_allocations || scope->storage!=old_storage) KernelStop;
      fun->exe_addr=address; service.val=(address+0)(U64);
      if(kind==3) HashAdd(&service,task->hash_table);
      if(kind==4 && !ProbePublishedRemove(task->hash_table,&collision)) KernelStop;
      if(kind==6) global->data_addr=catch_flag.val;
    }
    if(!probe->compiler->publish(heap,cc,symbols) || kind==5 && scope->storage!=old_storage ||
        kind!=5 && scope->storage==old_storage) KernelStop;
    if(!probe->compiler->control_unwind(task,outer)) KernelStop;
    if(ProbeProgramUse(probe,heap,outer,"ProbeResident(40);")!=42) KernelStop;
    if(kind!=5 && ProbeProgramUse(probe,heap,outer,"ResidentMain;")!=42) KernelStop;
    for(i=0;i<count;i++)
      if(!ProbePublishedRemove(task->hash_table,roots[i]) || !I386HashDel(heap,roots[i])) KernelStop;
    while(scope->storage!=old_storage) {
      storage=scope->storage; scope->storage=storage->next;
      for(i=0;i<storage->count;i++) if(!I386HeapFree(heap,storage->allocations[i])) KernelStop;
      if(!I386HeapFree(heap,storage)) KernelStop;
    }
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    if(!task->new_answer || task->answer_type!=0xA5) KernelStop;
    KernelLog("RESIDENT CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
  task->new_answer=old_answer; task->answer_type=old_answer_type;
  if(!ProbePublishedRemove(task->hash_table,&service) || !ProbePublishedRemove(task->hash_table,&catch_flag)) KernelStop;
}
