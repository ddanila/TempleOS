#include "/Kernel/I386/TaskStorage.HC"
//Publication must outlive the originating control and roll back failed validation.
#include "/Compiler/I386/SymbolDelete.HC"
Bool ProbePublishedRemove(CHashTable *table,CHash *entry)
{
  I64 i;
  CHash **link;
  for(i=0;i<=table->mask;i++) {
    link=&table->body[i];
    while(*link) {
      if(*link==entry) { *link=entry->next; entry->next=0; return TRUE; }
      link=&(*link)->next;
    }
  }
  return FALSE;
}
U0 ProbePublish(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CProbeSymbols *state;
  CHashClass *roots[6],*collision;
  CHashTable *table=task->hash_table;
  CCmpCtrl *cc;
  U8 *source,*name,*old_index,*fill,*block,*next;
  I64 kind,count,i,size,attr,before_used,before_allocations;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 irq,flags=GetRFlags;
  Bool result;
  for(kind=0;kind<10;kind++) {
    source="Durable { U8 bytes[2+3]; }"; count=1; collision=0; fill=0;
    if(!kind) {
      name=0;
      source=probe->files->read(heap,"C:/Kernel/Types.HH",&size,&attr,&name);
      if(!source || !name) KernelStop;
      irq=I386IrqSave; I386HeapFree(heap,name); I386IrqRestore(irq);
      count=6;
    }
    size=CCF_AOT_COMPILE;
    if(kind) size|=CCF_DONT_FREE_BUF;
    cc=probe->files->control_new(source,size,"Probe/Publish.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    state=ProbeSymbolSetup(probe,heap,cc);
    ProbeExpressionLex(state,cc);
    if(!kind) {
      ProbeScalarUnions(state,cc,FALSE);
      for(i=0;i<6;i++) roots[i]=state->scalars[i];
    } else roots[0]=ProbeSymbolJoin(state,cc,KW_CLASS,0,FALSE);
    old_index=roots[0]->idx;
    switch(kind) {
      case 1:
        irq=I386IrqSave;
        collision=I386HeapAlloc(heap,sizeof(CHashClass)*(PTR_STARS_NUM+1),TRUE);
        name=I386HeapAlloc(heap,8,FALSE);
        I386IrqRestore(irq);
        if(!collision || !name) KernelStop;
        PrsClassInit(collision);
        source="Durable"; for(i=0;i<8;i++) name[i]=source[i];
        collision->str=name;
        irq=I386IrqSave; HashAdd(collision,table); I386IrqRestore(irq);
        break;
      case 2: roots[0]->idx="Foreign"; break;
      case 3: roots[0]->idx=roots[0]->str; break;
      case 4:
        for(size=65536;size>=8;size=size/2)
          while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
        break;
      case 6:
        if(!probe->compiler->code_add(heap,cc,IC_IMM_I64,1,probe->i64_type,0)) KernelStop;
        break;
      case 7: cc->error_cnt=1; break;
      case 8:
        if(cc->cur_str) KernelStop;
        cc->cur_str=probe->compiler->parser_alloc(heap,cc,8,TRUE);
        source="Lexer"; for(i=0;i<6;i++) cc->cur_str[i]=source[i];
        roots[0]->idx=cc->cur_str;
        break;
      case 9:
        name=probe->compiler->parser_alloc(heap,cc,8,TRUE);
        source="Source"; for(i=0;i<7;i++) name[i]=source[i];
        irq=I386IrqSave;
        if(!I386HeapFree(heap,cc->lex_include_stk->full_name)) KernelStop;
        cc->lex_include_stk->full_name=name;
        I386IrqRestore(irq);
        roots[0]->idx=name;
        break;
    }
    before_used=heap->used; before_allocations=heap->allocations;
    if(kind==5) result=probe->compiler->publish_classes(heap,cc,table);
    else result=probe->compiler->publish_classes(heap,cc,state->table);
    if((GetRFlags&0x200)!=(flags&0x200) || result!=(kind==0)) KernelStop;
    if(kind) {
      if(heap->used!=before_used || heap->allocations!=before_allocations ||
          ProbeSymbolFind(state,"Durable",state->table,HTT_CLASS)!=roots[0] ||
          roots[0]->size!=5 || roots[0]->member_cnt!=1) KernelStop;
      roots[0]->idx=old_index;
      while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
      if(collision) {
        irq=I386IrqSave;
        if(!ProbePublishedRemove(table,collision) || !I386HashDel(heap,collision)) KernelStop;
        I386IrqRestore(irq);
      }
    } else {
      for(i=0;i<=state->table->mask;i++) if(state->table->body[i]) KernelStop;
      for(i=0;i<count;i++)
        if(ProbeSymbolFind(state,roots[i]->str,table,HTT_CLASS)!=roots[i]) KernelStop;
    }
    if(!probe->compiler->control_unwind(task,outer)) KernelStop;
    if(!kind) {
      //A fresh owner must see the published graph after all old parser state died.
      cc=probe->files->control_new("sizeof(U64.u32)+sizeof(U64 *)+0x100000001(U32);",
        CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/PublishedUse.HC");
      if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
      state=ProbeSymbolSetup(probe,heap,cc);
      ProbeExpressionLex(state,cc);
      if(ProbeDeclarationInteger(state,cc)!=13 || cc->token!=';') KernelStop;
      if(!probe->compiler->control_unwind(task,outer)) KernelStop;
      irq=I386IrqSave;
      for(i=0;i<count;i++) if(!ProbePublishedRemove(table,roots[i])) KernelStop;
      while(count) if(!I386HashDel(heap,roots[--count])) KernelStop;
      I386IrqRestore(irq);
    }
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs ||
        task->except_top || heap->used!=used || heap->allocations!=allocations ||
        !I386HeapValid(heap) || (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("PUBLICATION CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
