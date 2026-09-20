#include "/Kernel/I386/HelpFileCheck.HH"
Bool ProbePublicMemoryInput(CI386CompilerProbe *probe,CI386CommandInput *input,CProbeInputAnswer *answer,I64 index)
{
  Bool accepted=probe->compiler->input(input);
  KernelLog("PUBLIC MEMORY STEP "); KernelHex(probe->phase); KernelLog(" "); KernelHex(index);
  KernelLog(" "); KernelHex(accepted); KernelLog(" "); KernelHex(input->exception);
  KernelLog(" "); KernelHex(answer->value); KernelLog(" "); KernelHex(input->commands);
  KernelLog(" "); KernelHex(input->heap->used); KernelLog("\n");
  return accepted;
}
Bool ProbeDocLayoutInput(CI386CompilerProbe *probe,CI386CommandInput *input,I64 checks)
{
  I64 used=input->heap->used,allocations=input->heap->allocations;
  Bool accepted=probe->compiler->input(input);
  KernelLog("PUBLIC DOC LAYOUT "); KernelHex(probe->phase); KernelLog(" "); KernelHex(checks);
  KernelLog(" "); KernelHex(accepted); KernelLog(" "); KernelHex(input->exception); KernelLog("\n");
  return accepted && !input->warnings && !input->answers &&
    input->heap->used==used && input->heap->allocations==allocations;
}
I64 ProbeDocumentLayout(CI386CompilerProbe *probe,CI386CommandInput *input)
{
  CI386Heap *heap=input->heap;
  U8 *source,*name=0,*batch;
  I64 size,attr,start=0,end,i,length=0,checks=0;
  source=probe->files->read(heap,"C:/Kernel/I386/DocLayoutCheck.HH",&size,&attr,&name);
  if(!source || !name || size<1) KernelStop;
  batch=I386HeapAlloc(heap,size+1,FALSE);
  if(!batch) KernelStop;
  //Independent layout assertions need no shared compiler temporaries. Bound each
  //input and verify its reclamation while retaining the published type graph.
  while(start<size) {
    end=start; while(end<size && source[end]!=10) end++;
    if(end-start>7 && source[start]=='#' && source[start+1]=='a') {
      for(i=start;i<end;i++) batch[length++]=source[i];
      batch[length++]=10; checks++;
      if(!(checks%16)) {
        batch[length]=0; input->source=batch;
        if(!ProbeDocLayoutInput(probe,input,checks)) KernelStop;
        length=0;
      }
    }
    start=end+1;
  }
  if(length) {
    batch[length]=0; input->source=batch;
    if(!ProbeDocLayoutInput(probe,input,checks)) KernelStop;
  }
  input->source=0;
  if(!I386HeapFree(heap,batch) || !I386HeapFree(heap,source) || !I386HeapFree(heap,name)) KernelStop;
  return checks;
}
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
  CHashSrcSym *help;
  CHashClass *document_type;
  CMemberLst *document_member;
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
  help=ProbeSymbolFind(0,"C:/Doc/Que.DD.Z",table,HTT_HELP_FILE);
  if(!help || !(help->type&HTF_PUBLIC) || !help->src_link || !help->idx ||
      StrCmp(help->idx,"Data Types/Circular Queue")) KernelStop;
  input.source=I386_HELP_FILE_CHECK_SOURCE;
  if(!probe->compiler->input(&input)) KernelStop;
  help=ProbeSymbolFind(0,"C:/Doc/ProbeHelp.DD.Z",table,HTT_HELP_FILE);
  if(help) { KernelLog("PUBLIC HELP SOURCE "); KernelLog(help->src_link); KernelLog(" "); KernelLog(help->idx); KernelLog("\n"); }
  if(!help || !help->idx || StrCmp(help->idx,"Second") || !help->src_link ||
      StrCmp(help->src_link,"FL:C:/Probe/PublicHeaders.HC,5")) KernelStop;
  before_used=heap->used; before_allocations=heap->allocations;
  input.source="#help_file \"::/Doc/RollbackHelp\"\nUnknown bad;";
  if(probe->compiler->input(&input) || input.exception!='Compiler' ||
      ProbeSymbolFind(0,"C:/Doc/RollbackHelp.DD.Z",table,HTT_HELP_FILE) ||
      heap->used!=before_used || heap->allocations!=before_allocations) KernelStop;
  input.source="#help_index \"Third\"\n#help_file \"::/Doc/ProbeHelp.DD\"\n#help_file \"::/Doc/ProbeHelp\"\n";
  if(!probe->compiler->input(&input)) KernelStop;
  help=ProbeSymbolFind(0,"C:/Doc/ProbeHelp.DD.Z",table,HTT_HELP_FILE);
  if(!help || !help->idx || StrCmp(help->idx,"Third") ||
      !ProbeSymbolFind(0,"C:/Doc/ProbeHelp.DD",table,HTT_HELP_FILE)) KernelStop;
  KernelLog("PUBLIC HELP CASE "); KernelHex(probe->phase); KernelLog("\n");
  input.flags=0;
  input.source="Fs->addr==Fs && Fs->gs==Gs && Gs->addr==Gs && Gs->num==0;";
  if(!probe->compiler->input(&input) || answer.value!=1 || input.answers!=1) KernelStop;
  input.source="Fs->next_task->last_task==Fs && Fs->last_task->next_task==Fs && Fs->next_task->task_signature==TASK_SIGNATURE_VAL;";
  if(!probe->compiler->input(&input) || answer.value!=1) KernelStop;
  input.source="Fs->next_task!=Fs;";
  if(!probe->compiler->input(&input) || answer.value!=probe->phase) KernelStop;
  KernelLog("PUBLIC TASK RING "); KernelHex(probe->phase); KernelLog("\n");
  input.source="Fs->task_signature==TASK_SIGNATURE_VAL;";
  if(!probe->compiler->input(&input) || answer.value!=1) KernelStop;
  input.source="Fs->last_cc!=0 && Fs->hash_table->body!=0;";
  if(!probe->compiler->input(&input) || answer.value!=1) KernelStop;
  input.source="Fs->stk->stk_size>=256 && Fs->stk->next_stk==0 && Fs->stk->stk_ptr==0;";
  if(!probe->compiler->input(&input) || answer.value!=1) KernelStop;
  input.source="_intern 0x73 U8 *ProbeStackRsp();ProbeStackRsp>=(&Fs->stk->stk_base)(U64) && ProbeStackRsp<(&Fs->stk->stk_base)(U64)+Fs->stk->stk_size;";
  if(!probe->compiler->input(&input) || answer.value!=1) KernelStop;
  KernelLog("PUBLIC HEADER LIVE "); KernelHex(probe->phase); KernelLog("\n");
  //Public allocations outlive compilation controls and survive a failed input.
  //Use page allocations here so final Free returns backing, preserving the
  //probe's exact bootstrap accounting. Console checks cover cached small blocks.
  input.source="sizeof(CHeapCtrl)==1088 && sizeof(CBlkPool)==1276 && Fs->data_heap->mem_task==Fs;";
  if(!ProbePublicMemoryInput(probe,&input,&answer,0) || answer.value!=1) KernelStop;
  input.source="U8 *pub_mem=MAlloc(2048);";
  if(!ProbePublicMemoryInput(probe,&input,&answer,1)) KernelStop;
  input.source="pub_mem[2047]=42;";
  if(!ProbePublicMemoryInput(probe,&input,&answer,2) || answer.value!=42) KernelStop;
  input.source="Unknown memory_bad;";
  if(ProbePublicMemoryInput(probe,&input,&answer,3) || input.exception!='Compiler') KernelStop;
  input.source="pub_mem[2047]==42 && MHeapCtrl(pub_mem)==Fs->data_heap && MSize(pub_mem)>=2048 && MSize2(pub_mem)==MSize(pub_mem)+12;";
  if(!ProbePublicMemoryInput(probe,&input,&answer,4) || answer.value!=1) KernelStop;
  input.source="Free(pub_mem);";
  if(!ProbePublicMemoryInput(probe,&input,&answer,5)) KernelStop;
  input.source="pub_mem=CAllocAligned(2048,64,Fs->code_heap,3);";
  if(!ProbePublicMemoryInput(probe,&input,&answer,6)) KernelStop;
  input.source="pub_mem[0]==0 && pub_mem[2047]==0 && pub_mem(U64)%64==3 && MSize(pub_mem)==MSize(pub_mem+pub_mem(I64 *)[-1]);";
  if(!ProbePublicMemoryInput(probe,&input,&answer,7) || answer.value!=1) KernelStop;
  input.source="Free(pub_mem);Free(0);MSize(0)==0 && MSize2(0)==0 && MHeapCtrl(0)==0;";
  if(!ProbePublicMemoryInput(probe,&input,&answer,8) || answer.value!=1) KernelStop;
  input.source="extern U0 SysTry(U8 *caught,U8 *leave);extern U0 SysUntry();"
    "_intern 0x6C I64 MemProbeFlags();";
  if(!ProbePublicMemoryInput(probe,&input,&answer,9)) KernelStop;
  input.source="I64 MemFailure(){I64 ok=0,saved=MemProbeFlags&512;try{MAlloc(0x800000);}"
    "catch{ok=Fs->except_ch=='OutMem' && (MemProbeFlags&512)==saved;Fs->catch_except=1;}return ok;}"
    "MHeapCtrl(&MemFailure)==Fs->code_heap && MSize(&MemFailure)>0;";
  if(!ProbePublicMemoryInput(probe,&input,&answer,10) || answer.value!=1) KernelStop;
  input.source="MemFailure;";
  if(!ProbePublicMemoryInput(probe,&input,&answer,11) || answer.value!=1) KernelStop;
  KernelLog("PUBLIC MEMORY CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(12); KernelLog("\n");
  for(i=0;i<5;i++) {
    switch(i) {
      case 0: input.source="_intern 0x80 U0 QueueBad(U8 *head);"; break;
      case 1: input.source="_intern 0x83 U0 QueueBad(CQue **head);"; break;
      case 2: input.source="_intern 0x81 U0 QueueBad(CQue *entry,U8 *pred);"; break;
      case 3: input.source="_intern 0x82 I64 QueueBad(CQue *entry,CQue *succ);"; break;
      case 4: input.source="_intern 0x80 U0 QueueBad(CQue *head,CQue *extra);"; break;
    }
    before_used=heap->used; before_allocations=heap->allocations;
    if(probe->compiler->input(&input) || ProbeSymbolFind(0,"QueueBad",table,HTT_FUN) ||
        heap->used!=before_used || heap->allocations!=before_allocations) KernelStop;
    KernelLog("PUBLIC QUEUE REJECT "); KernelHex(probe->phase); KernelLog(" "); KernelHex(i); KernelLog("\n");
  }
  input.source="#include \"/Kernel/I386/QueueCheck.HC\"\nQueueCheck;";
  accepted=probe->compiler->input(&input);
  KernelLog("PUBLIC QUEUE RESULT "); KernelHex(probe->phase); KernelLog(" "); KernelHex(accepted);
  KernelLog(" "); KernelHex(input.exception); KernelLog(" "); KernelHex(answer.value);
  KernelLog(" "); KernelHex(input.answers); KernelLog("\n");
  if(!accepted || input.answers!=1 || answer.value!=9) KernelStop;
  KernelLog("PUBLIC QUEUE CASE "); KernelHex(probe->phase); KernelLog("\n");
  input.source="#include \"/Kernel/I386/BitEquCheck.HC\"\nBitEquCheck(&BEqu,&LBEqu);";
  before_used=heap->used;
  accepted=probe->compiler->input(&input);
  KernelLog("PUBLIC BIT MEMORY "); KernelHex(probe->phase); KernelLog(" "); KernelHex(before_used);
  KernelLog(" "); KernelHex(heap->used); KernelLog(" "); KernelHex(heap->peak);
  KernelLog(" "); KernelHex(heap->size); KernelLog(" "); KernelHex(I386HeapValid(heap));
  KernelLog(" "); KernelHex(input.commands); KernelLog("\n");
  KernelLog("PUBLIC BIT EQU "); KernelHex(probe->phase); KernelLog(" "); KernelHex(accepted);
  KernelLog(" "); KernelHex(input.exception); KernelLog(" "); KernelHex(answer.value); KernelLog("\n");
  if(!accepted || input.exception || input.answers!=1 || answer.value!=168) {
    KernelLog("PUBLIC BIT FAILURE "); KernelHex(task->except_rbp-(&task->stk->stk_base)(U64));
    KernelLog(" "); KernelHex(task->stk->stk_size);
    for(i=0;i<TASK_EXCEPT_CALLERS;i++) { KernelLog(" "); KernelHex((task->except_callers[i]+0)(U64)); }
    KernelLog("\n"); KernelStop;
  }
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
  if(checks!=113 || !probe->compiler->input(&input) || input.warnings || input.answers) KernelStop;
  if(!I386HeapFree(heap,bytes) || !I386HeapFree(heap,source) || !I386HeapFree(heap,name)) KernelStop;
  KernelLog("PUBLIC HEADER LAYOUT "); KernelHex(probe->phase); KernelLog(" "); KernelHex(checks); KernelLog("\n");
  checks=ProbeDocumentLayout(probe,&input);
  if(checks!=271) KernelStop;
  document_type=ProbeSymbolFind(0,"CEdFindText",table,HTT_CLASS);
  if(!document_type || !(document_member=document_type->member_lst_and_root) ||
      StrCmp(document_member->str,"find_text") || !document_member->meta ||
      StrCmp(document_member->meta->str,"format") || !(document_member->meta->flags&MLMF_IS_STR) ||
      StrCmp(document_member->meta->user_data,"$$DA-P,A=\"Find        :%s\"$$\n")) KernelStop;
  input.source="#include \"/Kernel/I386/DocRecordCheck.HC\"\nDocRecordCheck;";
  accepted=probe->compiler->input(&input);
  KernelLog("PUBLIC DOC RESULT "); KernelHex(probe->phase); KernelLog(" "); KernelHex(accepted);
  KernelLog(" "); KernelHex(input.exception); KernelLog(" "); KernelHex(answer.value); KernelLog("\n");
  if(!accepted || input.answers!=1 || answer.value!=4) KernelStop;
  KernelLog("PUBLIC DOC CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(checks); KernelLog("\n");
  for(i=0;i<=table->mask;i++)
    while((entry=table->body[i])!=heads[i]) {
      if(!entry) KernelStop;
      table->body[i]=entry->next;
      if(!I386HashDel(heap,entry)) KernelStop;
    }
  while(scope->storage!=old_storage) {
    storage=scope->storage; scope->storage=storage->next;
    if(!I386TaskStorageRelease(heap,storage)) KernelStop;
  }
  if(!I386HeapFree(heap,heads) || task->last_cc!=outer || task->active_controls!=1 ||
      task->lifetime_refs!=refs || task->except_top || heap->used!=used ||
      heap->allocations!=allocations || !I386HeapValid(heap) ||
      (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  KernelLog("PUBLIC HEADER CASE "); KernelHex(probe->phase); KernelLog("\n");
}
