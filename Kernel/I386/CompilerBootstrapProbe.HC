U8 *ProbeBootstrapNoRead(CI386Heap *heap,U8 *filename,I64 *size,I64 *attr,U8 **name)
{ return 0; }
U0 ProbeBootstrap(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CHashClass *roots[6];
  CHashTable *table=task->hash_table;
  CI386FileServices files;
  CCmpCtrl *cc;
  U8 *source,*name,*fill,*block,*next;
  I64 kind,i,j,size,attr,accepted,before_used,before_allocations;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 irq,flags=GetRFlags;
  for(kind=0;kind<7;kind++) {
    if(!kind) {
      if(!probe->compiler->load_scalar_types(heap,probe->internal_types,probe->files,probe->disk_include)) KernelStop;
      name="U16\0I16\0U32\0I32\0U64\0I64";
      for(i=0;i<6;i++,name+=4) {
        roots[i]=ProbeSymbolFind(0,name,table,HTT_CLASS);
        if(!roots[i] || !roots[i]->src_link || !roots[i]->idx || StrCmp(roots[i]->idx,"Data Types/Simple")) KernelStop;
        KernelLog("BOOTSTRAP SOURCE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(i); KernelLog(" ");
        KernelLog(roots[i]->src_link); KernelLog("\n");
      }
      before_used=heap->used; before_allocations=heap->allocations;
      if(probe->compiler->load_scalar_types(heap,probe->internal_types,probe->files,probe->disk_include) ||
          heap->used!=before_used || heap->allocations!=before_allocations || task->last_cc!=outer) KernelStop;
      irq=I386IrqSave;
      for(i=0;i<6;i++) if(!ProbePublishedRemove(table,roots[i])) KernelStop;
      for(i=0;i<6;i++) if(!I386HashDel(heap,roots[i])) KernelStop;
      I386IrqRestore(irq);
    } else if(kind==4) {
      files.version=I386_FILE_SERVICES_VERSION; files.bytes=sizeof(CI386FileServices);
      files.read=&ProbeBootstrapNoRead; files.control_new=probe->files->control_new;
      if(probe->compiler->load_scalar_types(heap,probe->internal_types,&files,probe->disk_include)) KernelStop;
    } else {
      source="U16i union U16 { I8i i8[2+]; U8i u8[2]; };";
      if(kind==2 || kind==5) source="#help_index \"Data Types/Simple\"\nU16i union U16 { I8i i8[2]; U8i u8[2]; };";
      name="Probe/Bootstrap.HC";
      if(kind==3 || kind==6) {
        name=0;
        source=probe->files->read(heap,"C:/Kernel/Types.HH",&size,&attr,&name);
        if(!source || !name) KernelStop;
        for(i=0;i<size-4;i++) {
          if(kind==3 && source[i]=='U' && source[i+1]=='1' && source[i+2]=='6' && source[i+3]=='i') { source[i]='I'; break; }
          if(kind==6 && source[i]=='D' && source[i+1]=='a' && source[i+2]=='t' && source[i+3]=='a') { source[i]='X'; break; }
        }
        if(i==size-4) KernelStop;
      }
      attr=CCF_AOT_COMPILE;
      if(kind!=3 && kind!=6) attr|=CCF_DONT_FREE_BUF;
      cc=probe->files->control_new(source,attr,name);
      if(kind==3 || kind==6) { irq=I386IrqSave; I386HeapFree(heap,name); I386IrqRestore(irq); }
      if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
      fill=0; accepted=0;
      try {
        if(kind==5) for(size=65536;size>=8;size=size/2)
          while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
        probe->compiler->bootstrap_scalars(heap,cc,probe->internal_types,probe->disk_include);
        KernelStop;
      } catch {
        if(kind==5 && task->except_ch!='OutMem' || kind!=5 && task->except_ch!='Compiler') KernelStop;
        task->catch_except=TRUE; accepted=1;
      }
      while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
      if(!accepted || !probe->compiler->control_unwind(task,outer)) KernelStop;
    }
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("BOOTSTRAP CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
