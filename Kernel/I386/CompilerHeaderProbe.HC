//Load the actual public headers, retry failure, and compare every public offset.
U0 ProbePublicHeaders(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskStorage *old_storage=scope->storage,*storage;
  CHashTable *table=task->hash_table;
  CHash **heads;
  CHash *entry;
  CHashClass *forward;
  CI386CommandInput input;
  CProbeInputAnswer answer;
  U8 *bytes,*source,*name;
  I64 i,j,start,end,length,size,attr,checks=0;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs,before_used,before_allocations;
  U32 flags=GetRFlags;
  Bool skip,accepted;
  KernelLog("PUBLIC HEADER PROBE START "); KernelHex(probe->phase); KernelLog("\n");
  heads=I386HeapAlloc(heap,(table->mask+1)*sizeof(CHash *),FALSE);
  if(!heads) KernelStop;
  for(i=0;i<=table->mask;i++) heads[i]=table->body[i];
  if(!probe->compiler->load_scalar_types(heap,probe->internal_types,probe->files,probe->disk_include)) KernelStop;
  bytes=&input; for(i=0;i<sizeof(CI386CommandInput);i++) bytes[i]=0;
  bytes=&answer; for(i=0;i<sizeof(CProbeInputAnswer);i++) bytes[i]=0;
  input.heap=heap; input.types=probe->internal_types; input.files=probe->files;
  input.includes=probe->disk_include; input.filename="Probe/PublicHeaders.HC";
  input.context=&answer; input.answer=&ProbeInputAnswer; input.diagnostic=&ProbeInputDiagnostic;
  input.source="extern class CTask;";
  if(!probe->compiler->input(&input)) KernelStop;
  forward=ProbeSymbolFind(0,"CTask",table,HTT_CLASS);
  if(!forward || !Bt(&forward->flags,Cf_EXTERN)) KernelStop;
  before_used=heap->used; before_allocations=heap->allocations;
  input.flags=I386_INPUT_ATOMIC_DEFINES|CCF_JUST_LOAD;
  input.source="#include \"/Kernel/I386/PublicKernel.HH\"\nUnknown bad;";
  if(probe->compiler->input(&input) || input.exception!='Compiler' ||
      !Bt(&forward->flags,Cf_EXTERN) || forward->size ||
      ProbeSymbolFind(0,"I386_PUBLIC_KERNEL_INCLUDED",table,HTT_DEFINE_STR) ||
      ProbeSymbolFind(0,"CCPU",table,HTT_CLASS) ||
      heap->used!=before_used || heap->allocations!=before_allocations) KernelStop;
  KernelLog("PUBLIC HEADER ROLLBACK "); KernelHex(probe->phase); KernelLog("\n");
  input.source="#include \"/Kernel/I386/PublicKernel.HH\"\n";
  answer.diagnostics=0;
  accepted=probe->compiler->input(&input);
  KernelLog("PUBLIC HEADER PUBLISHED "); KernelHex(accepted); KernelLog(" ");
  KernelHex(input.warnings); KernelLog(" "); KernelHex(forward->size); KernelLog("\n");
  //CCPU retains the existing count-only unused-forward warning. Assertions
  //must produce no diagnostic, and no additional warning is accepted.
  if(!accepted || input.warnings!=1 || answer.diagnostics ||
      ProbeSymbolFind(0,"CTask",table,HTT_CLASS)!=forward ||
      Bt(&forward->flags,Cf_EXTERN) || forward->size!=sizeof(CTask)) KernelStop;
  before_used=heap->used; before_allocations=heap->allocations;
  if(!probe->compiler->input(&input) || input.warnings || heap->used!=before_used ||
      heap->allocations!=before_allocations) KernelStop;
  input.flags=0;
  input.source="Fs->addr==Fs && Fs->gs==Gs && Gs->addr==Gs && Gs->num==0;";
  if(!probe->compiler->input(&input) || answer.value!=1 || input.answers!=1) KernelStop;
  input.source="Fs->task_signature==TASK_SIGNATURE_VAL;";
  if(!probe->compiler->input(&input) || answer.value!=1) KernelStop;
  input.source="Fs->last_cc!=0 && Fs->hash_table->body!=0;";
  if(!probe->compiler->input(&input) || answer.value!=1) KernelStop;
  KernelLog("PUBLIC HEADER LIVE "); KernelHex(probe->phase); KernelLog("\n");
  //Reuse the AOT layout assertions as native source. Exclude private extension
  //checks and separate assertions with semicolons to bound lexer recursion.
  name=0;
  source=probe->files->read(heap,"C:/Kernel/I386/CompilerTaskLayoutProbe.HC",&size,&attr,&name);
  if(!source || !name) KernelStop;
  bytes=I386HeapAlloc(heap,size*2+1,FALSE);
  if(!bytes) KernelStop;
  length=0; start=0;
  while(start<size) {
    end=start; while(end<size && source[end]!=10) end++;
    if(source[start]=='_') break;
    if(end-start>7 && source[start]=='#') {
      skip=FALSE;
      for(j=start;j+4<end;j++)
        if(source[j]=='C' && source[j+1]=='I' && source[j+2]=='3' && source[j+3]=='8' && source[j+4]=='6') skip=TRUE;
      if(!skip) {
        for(j=start;j<end;j++) bytes[length++]=source[j];
        bytes[length++]=';'; bytes[length++]=10; checks++;
      }
    }
    start=end+1;
  }
  bytes[length]=0; input.source=bytes;
  if(checks!=108 || !probe->compiler->input(&input) || input.warnings || input.answers) KernelStop;
  if(!I386HeapFree(heap,bytes) || !I386HeapFree(heap,source) || !I386HeapFree(heap,name)) KernelStop;
  KernelLog("PUBLIC HEADER LAYOUT "); KernelHex(probe->phase); KernelLog(" "); KernelHex(checks); KernelLog("\n");
  for(i=0;i<=table->mask;i++)
    while((entry=table->body[i])!=heads[i]) {
      if(!entry) KernelStop;
      table->body[i]=entry->next;
      if(!I386HashDel(heap,entry)) KernelStop;
    }
  while(scope->storage!=old_storage) {
    storage=scope->storage; scope->storage=storage->next;
    for(i=0;i<storage->count;i++) if(!I386HeapFree(heap,storage->allocations[i])) KernelStop;
    if(!I386HeapFree(heap,storage)) KernelStop;
  }
  if(!I386HeapFree(heap,heads) || task->last_cc!=outer || task->active_controls!=1 ||
      task->lifetime_refs!=refs || task->except_top || heap->used!=used ||
      heap->allocations!=allocations || !I386HeapValid(heap) ||
      (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  KernelLog("PUBLIC HEADER CASE "); KernelHex(probe->phase); KernelLog("\n");
}
