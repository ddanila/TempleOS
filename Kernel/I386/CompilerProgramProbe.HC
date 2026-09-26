//Definitions must survive control destruction and later failed input.
U8 *ProbeProgramRead(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *cc,
  CPrsSymbolServices *symbols,Bool execute=TRUE)
{
  CPrsDeclarationServices *d=symbols->declarations;
  CPrsExpressionServices *e=d->expression;
  U8 *code,*last=0;
  I64 type,count=0;
  e->report=&ProbeExpressionReport; d->types->report=&ProbeExpressionReport;
  e->lex(e->context,cc);
  while(cc->token!=TK_EOF) {
    if(++count>32) KernelStop;
    code=probe->compiler->command(heap,cc,symbols,&type);
    if(code) {
      if(execute) d->execute(d->context,code);
      if(cc->flags&CCF_HAS_MISC_DATA) last=code;
      else d->release(d->context,code);
    }
  }
  return last;
}
I64 ProbeProgramUse(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer,U8 *source)
{
  CCmpCtrl *cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/ProgramUse.HC");
  CPrsSymbolServices *symbols;
  CPrsDeclarationServices *d;
  CPrsExpressionServices *e;
  U8 *code;
  I64 type,value=0;
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
  if(!symbols) KernelStop;
  d=symbols->declarations; e=d->expression;
  e->lex(e->context,cc);
  while(cc->token!=TK_EOF) {
    code=probe->compiler->command(heap,cc,symbols,&type);
    if(code) { value=d->execute(d->context,code); d->release(d->context,code); }
  }
  if(!probe->compiler->control_unwind(I386TaskSelf,outer)) KernelStop;
  return value;
}
U0 ProbeProgramJitSpan(CI386CompilerProbe *probe,CPrsSymbolServices *symbols,
  CHashTable *table,U8 *name,I64 phase,I64 index)
{
  CHashFun *function=ProbeSymbolFind(0,name,table,HTT_FUN);
  I64 bytes,*data_start,i;
  if(!function || !function->exe_addr ||
      !probe->compiler->code_span(symbols,function->exe_addr,&bytes,&data_start) ||
      bytes<1 || bytes>4096 || *data_start<1 || *data_start>bytes) KernelStop;
  KernelLog("JIT SPAN "); KernelHex(phase); KernelLog(" "); KernelHex(index);
  KernelLog(" "); KernelHex(bytes); KernelLog(" "); KernelHex(*data_start); KernelLog("\n");
  KernelLog("JIT BYTES "); KernelHex(phase); KernelLog(" "); KernelHex(index);
  for(i=0;i<bytes;i++) { KernelLog(" "); KernelHex(function->exe_addr[i]); }
  KernelLog("\n");
}
U0 ProbeProgramModule(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function=ProbeSymbolFind(0,"DurableConst",table,HTT_FUN);
  CI386ModuleRecord record;
  U8 *module=0,*image=0,*disk_module=0;
  I64 code_bytes,*data_start,module_bytes,image_bytes,disk_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  I64 (*entry)();
  if(!function || !function->exe_addr ||
      !probe->compiler->code_span(symbols,function->exe_addr,&code_bytes,&data_start) ||
      code_bytes<1 || *data_start!=code_bytes) KernelStop;
  record.kind=I386_MODULE_EXPORT; record.offset=0; record.name_offset=0; record.name_length=12;
  record.name_offset=13;
  if(probe->compiler->module_pack(0,0,function->exe_addr,code_bytes,
      &record,1,"DurableConst",13)) KernelStop;
  record.name_offset=0;
  module_bytes=probe->compiler->module_pack(0,0,function->exe_addr,code_bytes,
    &record,1,"DurableConst",13);
  if(module_bytes<1) KernelStop;
  module=I386HeapAlloc(heap,module_bytes);
  if(!module) KernelStop;
  module[0]=0xA5;
  if(probe->compiler->module_pack(module,module_bytes-1,function->exe_addr,code_bytes,
      &record,1,"DurableConst",13) || module[0]!=0xA5) KernelStop;
  if(!module || probe->compiler->module_pack(module,module_bytes,function->exe_addr,code_bytes,
      &record,1,"DurableConst",13)!=module_bytes || !I386ModuleValid(module,module_bytes)) KernelStop;
  if(probe->persist_modules) {
    //The second writable boot must execute the bytes left by the first one.
    disk_module=probe->files->read(heap,"C:/Probe/DurableConst.t32m",&disk_bytes,0,0);
    if(disk_module) {
      if(disk_bytes!=module_bytes || !I386ModuleValid(disk_module,disk_bytes)) KernelStop;
      image_bytes=I386LoadBoundInto(&disk_module,&disk_bytes,1,0,0,"DurableConst",0,0);
      image=I386HeapAlloc(heap,image_bytes);
      if(!image || I386LoadBoundInto(&disk_module,&disk_bytes,1,image,image_bytes,
          "DurableConst",0,0)!=image_bytes) KernelStop;
      entry=image;
      if((*entry)()!=42 || !I386HeapFree(heap,image) || !I386HeapFree(heap,disk_module)) KernelStop;
      image=0; disk_module=0;
      KernelLog("NATIVE MODULE EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurableConst.t32m",module,module_bytes,0)) KernelStop;
    disk_module=probe->files->read(heap,"C:/Probe/DurableConst.t32m",&disk_bytes,0,0);
    if(!disk_module || disk_bytes!=module_bytes || !I386ModuleValid(disk_module,disk_bytes)) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk_module[i]!=module[i]) KernelStop;
    image_bytes=I386LoadBoundInto(&disk_module,&disk_bytes,1,0,0,"DurableConst",0,0);
    image=I386HeapAlloc(heap,image_bytes);
    if(!image || I386LoadBoundInto(&disk_module,&disk_bytes,1,image,image_bytes,
        "DurableConst",0,0)!=image_bytes) KernelStop;
    entry=image;
    if((*entry)()!=42 || !I386HeapFree(heap,image) || !I386HeapFree(heap,disk_module)) KernelStop;
    image=0; disk_module=0;
    KernelLog("NATIVE MODULE DISK\n");
  }
  image_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableConst",0,0);
  if(image_bytes<1) KernelStop;
  image=I386HeapAlloc(heap,image_bytes);
  if(!image || I386LoadBoundInto(&module,&module_bytes,1,image,image_bytes,"DurableConst",0,0)!=image_bytes) KernelStop;
  entry=image;
  if((*entry)()!=42 || !I386HeapFree(heap,image) || !I386HeapFree(heap,module) ||
      heap->used!=used || heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE MODULE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(module_bytes);
  KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
U0 ProbeProgramRelocation(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function=ProbeSymbolFind(0,"DurableFact",table,HTT_FUN);
  CI386FrontendRelocView reloc[2];
  CI386ModuleRecord records[2];
  U8 *code=0,*module=0,*image=0,*modules[1];
  I64 sizes[1],code_bytes,*data_start,module_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  I64 (*entry)(I64 n);
  if(!function || !function->exe_addr ||
      !probe->compiler->code_span(symbols,function->exe_addr,&code_bytes,&data_start) ||
      code_bytes<1 || code_bytes>4096 || *data_start!=code_bytes ||
      probe->compiler->code_relocs(symbols,function->exe_addr,0,0)!=1 ||
      probe->compiler->code_relocs(symbols,function->exe_addr,reloc,2)!=1 ||
      StrCmp(reloc[0].name,"DurableFact") || reloc[0].offset<1 ||
      reloc[0].offset>code_bytes-4 || function->exe_addr[reloc[0].offset-1]!=0xE8) KernelStop;
  code=I386HeapAlloc(heap,code_bytes);
  if(!code) KernelStop;
  for(i=0;i<code_bytes;i++) code[i]=function->exe_addr[i];
  (code+reloc[0].offset)(U32 *)[0]=0;
  records[0].kind=I386_MODULE_EXPORT; records[0].offset=0;
  records[0].name_offset=0; records[0].name_length=11;
  records[1].kind=I386_MODULE_REL32; records[1].offset=reloc[0].offset;
  records[1].name_offset=0; records[1].name_length=11;
  module_bytes=probe->compiler->module_pack(0,0,code,code_bytes,records,2,"DurableFact",12);
  if(module_bytes<1 || !(module=I386HeapAlloc(heap,module_bytes)) ||
      probe->compiler->module_pack(module,module_bytes,code,code_bytes,records,2,
        "DurableFact",12)!=module_bytes || !I386ModuleValid(module,module_bytes)) KernelStop;
  modules[0]=module; sizes[0]=module_bytes;
  image_bytes=I386LoadBoundInto(modules,sizes,1,0,0,"DurableFact",0,0);
  image=I386HeapAlloc(heap,image_bytes);
  if(!image || I386LoadBoundInto(modules,sizes,1,image,image_bytes,"DurableFact",0,0)!=image_bytes) KernelStop;
  entry=image;
  if((*entry)(5)!=120 || !I386HeapFree(heap,image) || !I386HeapFree(heap,module) ||
      !I386HeapFree(heap,code) || heap->used!=used || heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE RELOC "); KernelHex(probe->phase); KernelLog(" "); KernelHex(module_bytes);
  KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramMultiRun(CI386Heap *heap,U8 *module,I64 module_bytes)
{
  U8 *image,*literal;
  I64 image_bytes,text_bytes;
  I64 (*entry)();
  U8 *(*text_entry)();
  if(!I386ModuleValid(module,module_bytes)) KernelStop;
  image_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableRoot",0,0);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes))) KernelStop;
  if(I386LoadBoundInto(&module,&module_bytes,1,image,image_bytes,
      "DurableRoot",0,0)!=image_bytes) KernelStop;
  entry=image;
  if((*entry)()!=42 || !I386HeapFree(heap,image)) KernelStop;
  text_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableText",0,0);
  if(text_bytes!=image_bytes || !(image=I386HeapAlloc(heap,text_bytes)) ||
      I386LoadBoundInto(&module,&module_bytes,1,image,text_bytes,
        "DurableText",0,0)!=text_bytes) KernelStop;
  text_entry=image; literal=(*text_entry)();
  if((literal+0)(U64)<(image+0)(U64) ||
      (literal+0)(U64)>(image+image_bytes-6)(U64) ||
      StrCmp(literal,"hello") || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
I64 ProbeProgramBoundRun(CI386Heap *heap,U8 *module,I64 module_bytes,U8 *leaf)
{
  CI386ModuleBinding binding;
  U8 *image;
  I64 image_bytes;
  I64 (*entry)();
  binding.name="DurableLeaf";
  binding.kind=I386_MODULE_EXPORT;
  binding.address=(leaf+0)(U64);
  if(!I386ModuleValid(module,module_bytes) ||
      I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableRoot",0,0)) KernelStop;
  image_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableRoot",&binding,1);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes))) KernelStop;
  if(I386LoadBoundInto(&module,&module_bytes,1,image,image_bytes,
      "DurableRoot",&binding,1)!=image_bytes) KernelStop;
  entry=image;
  if((*entry)()!=42 || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramBound(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *functions[1],*leaf;
  U8 *module,*disk_module;
  I64 module_bytes,disk_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  leaf=ProbeSymbolFind(0,"DurableLeaf",table,HTT_FUN);
  functions[0]=ProbeSymbolFind(0,"DurableRoot",table,HTT_FUN);
  if(!leaf || !leaf->exe_addr || !functions[0] ||
      !(module_bytes=probe->compiler->program_pack(symbols,functions,1,0,0)) ||
      !(module=I386HeapAlloc(heap,module_bytes)) ||
      probe->compiler->program_pack(symbols,functions,1,module,module_bytes)!=module_bytes)
    KernelStop;
  image_bytes=ProbeProgramBoundRun(heap,module,module_bytes,leaf->exe_addr);
  if(probe->persist_modules) {
    disk_module=probe->files->read(heap,"C:/Probe/DurableBound.t32m",&disk_bytes,0,0);
    if(disk_module) {
      if(ProbeProgramBoundRun(heap,disk_module,disk_bytes,leaf->exe_addr)!=image_bytes ||
          !I386HeapFree(heap,disk_module)) KernelStop;
      KernelLog("NATIVE BOUND EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurableBound.t32m",module,module_bytes,0)) KernelStop;
    disk_module=probe->files->read(heap,"C:/Probe/DurableBound.t32m",&disk_bytes,0,0);
    if(!disk_module || disk_bytes!=module_bytes) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk_module[i]!=module[i]) KernelStop;
    if(ProbeProgramBoundRun(heap,disk_module,disk_bytes,leaf->exe_addr)!=image_bytes ||
        !I386HeapFree(heap,disk_module)) KernelStop;
    KernelLog("NATIVE BOUND DISK\n");
  }
  if(!I386HeapFree(heap,module) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE BOUND "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(module_bytes); KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramSplitRun(CI386Heap *heap,U8 *root,I64 root_bytes,U8 *leaf,I64 leaf_bytes)
{
  U8 *modules[2],*image;
  I64 sizes[2],image_bytes;
  I64 (*entry)();
  modules[0]=root; modules[1]=leaf;
  sizes[0]=root_bytes; sizes[1]=leaf_bytes;
  if(!I386ModuleValid(root,root_bytes) || !I386ModuleValid(leaf,leaf_bytes)) KernelStop;
  image_bytes=I386LoadBoundInto(modules,sizes,2,0,0,"DurableRoot",0,0);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes)) ||
      I386LoadBoundInto(modules,sizes,2,image,image_bytes,"DurableRoot",0,0)!=image_bytes)
    KernelStop;
  entry=image;
  if((*entry)()!=42 || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramSplit(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function[1];
  U8 *root,*leaf,*disk_root,*disk_leaf;
  I64 root_bytes,leaf_bytes,disk_root_bytes,disk_leaf_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  function[0]=ProbeSymbolFind(0,"DurableRoot",table,HTT_FUN);
  if(!function[0] ||
      !(root_bytes=probe->compiler->program_pack(symbols,function,1,0,0)) ||
      !(root=I386HeapAlloc(heap,root_bytes)) ||
      probe->compiler->program_pack(symbols,function,1,root,root_bytes)!=root_bytes)
    KernelStop;
  function[0]=ProbeSymbolFind(0,"DurableLeaf",table,HTT_FUN);
  if(!function[0] ||
      !(leaf_bytes=probe->compiler->program_pack(symbols,function,1,0,0)) ||
      !(leaf=I386HeapAlloc(heap,leaf_bytes)) ||
      probe->compiler->program_pack(symbols,function,1,leaf,leaf_bytes)!=leaf_bytes)
    KernelStop;
  image_bytes=ProbeProgramSplitRun(heap,root,root_bytes,leaf,leaf_bytes);
  if(probe->persist_modules) {
    disk_leaf=probe->files->read(heap,"C:/Probe/DurableLeaf.t32m",&disk_leaf_bytes,0,0);
    if(disk_leaf) {
      disk_root=probe->files->read(heap,"C:/Probe/DurableBound.t32m",&disk_root_bytes,0,0);
      if(!disk_root || ProbeProgramSplitRun(heap,disk_root,disk_root_bytes,
          disk_leaf,disk_leaf_bytes)!=image_bytes || !I386HeapFree(heap,disk_root) ||
          !I386HeapFree(heap,disk_leaf)) KernelStop;
      KernelLog("NATIVE SPLIT EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurableLeaf.t32m",leaf,leaf_bytes,0)) KernelStop;
    disk_root=probe->files->read(heap,"C:/Probe/DurableBound.t32m",&disk_root_bytes,0,0);
    disk_leaf=probe->files->read(heap,"C:/Probe/DurableLeaf.t32m",&disk_leaf_bytes,0,0);
    if(!disk_root || !disk_leaf || disk_root_bytes!=root_bytes ||
        disk_leaf_bytes!=leaf_bytes) KernelStop;
    for(i=0;i<root_bytes;i++) if(disk_root[i]!=root[i]) KernelStop;
    for(i=0;i<leaf_bytes;i++) if(disk_leaf[i]!=leaf[i]) KernelStop;
    if(ProbeProgramSplitRun(heap,disk_root,disk_root_bytes,disk_leaf,disk_leaf_bytes)!=image_bytes ||
        !I386HeapFree(heap,disk_root) || !I386HeapFree(heap,disk_leaf)) KernelStop;
    KernelLog("NATIVE SPLIT DISK\n");
  }
  if(!I386HeapFree(heap,root) || !I386HeapFree(heap,leaf) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE SPLIT "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(root_bytes); KernelLog(" "); KernelHex(leaf_bytes);
  KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramAddressRun(CI386Heap *heap,U8 *module,I64 module_bytes,
  U8 *leaf,I64 leaf_bytes)
{
  U8 *modules[2],*image,*target;
  CI386ModuleHeader *header=module;
  I64 sizes[2],image_bytes;
  U8 *(*entry)();
  I64 (*leaf_entry)();
  modules[0]=module; modules[1]=leaf;
  sizes[0]=module_bytes; sizes[1]=leaf_bytes;
  if(!I386ModuleValid(module,module_bytes) || !I386ModuleValid(leaf,leaf_bytes) ||
      I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableAddress",0,0)) KernelStop;
  image_bytes=I386LoadBoundInto(modules,sizes,2,0,0,"DurableAddress",0,0);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes)) ||
      I386LoadBoundInto(modules,sizes,2,image,image_bytes,"DurableAddress",0,0)!=image_bytes)
    KernelStop;
  entry=image; target=(*entry)();
  if(target!=image+8+header->code_size) KernelStop;
  leaf_entry=target;
  if((*leaf_entry)()!=41 || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramAddress(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function[1];
  U8 *module,*leaf,*disk_module,*disk_leaf;
  I64 module_bytes,leaf_bytes,disk_module_bytes,disk_leaf_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  function[0]=ProbeSymbolFind(0,"DurableAddress",table,HTT_FUN);
  if(!function[0] ||
      !(module_bytes=probe->compiler->program_pack(symbols,function,1,0,0)) ||
      !(module=I386HeapAlloc(heap,module_bytes)) ||
      probe->compiler->program_pack(symbols,function,1,module,module_bytes)!=module_bytes)
    KernelStop;
  function[0]=ProbeSymbolFind(0,"DurableLeaf",table,HTT_FUN);
  if(!function[0] ||
      !(leaf_bytes=probe->compiler->program_pack(symbols,function,1,0,0)) ||
      !(leaf=I386HeapAlloc(heap,leaf_bytes)) ||
      probe->compiler->program_pack(symbols,function,1,leaf,leaf_bytes)!=leaf_bytes)
    KernelStop;
  image_bytes=ProbeProgramAddressRun(heap,module,module_bytes,leaf,leaf_bytes);
  if(probe->persist_modules) {
    disk_module=probe->files->read(heap,"C:/Probe/DurableAddress.t32m",&disk_module_bytes,0,0);
    if(disk_module) {
      disk_leaf=probe->files->read(heap,"C:/Probe/DurableLeaf.t32m",&disk_leaf_bytes,0,0);
      if(!disk_leaf || ProbeProgramAddressRun(heap,disk_module,disk_module_bytes,
          disk_leaf,disk_leaf_bytes)!=image_bytes || !I386HeapFree(heap,disk_module) ||
          !I386HeapFree(heap,disk_leaf)) KernelStop;
      KernelLog("NATIVE ADDRESS EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurableAddress.t32m",module,module_bytes,0)) KernelStop;
    disk_module=probe->files->read(heap,"C:/Probe/DurableAddress.t32m",&disk_module_bytes,0,0);
    disk_leaf=probe->files->read(heap,"C:/Probe/DurableLeaf.t32m",&disk_leaf_bytes,0,0);
    if(!disk_module || !disk_leaf || disk_module_bytes!=module_bytes ||
        disk_leaf_bytes!=leaf_bytes) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk_module[i]!=module[i]) KernelStop;
    for(i=0;i<leaf_bytes;i++) if(disk_leaf[i]!=leaf[i]) KernelStop;
    if(ProbeProgramAddressRun(heap,disk_module,disk_module_bytes,
        disk_leaf,disk_leaf_bytes)!=image_bytes || !I386HeapFree(heap,disk_module) ||
        !I386HeapFree(heap,disk_leaf)) KernelStop;
    KernelLog("NATIVE ADDRESS DISK\n");
  }
  if(!I386HeapFree(heap,module) || !I386HeapFree(heap,leaf) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE ADDRESS "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(module_bytes); KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramDataRun(CI386Heap *heap,U8 *module,I64 module_bytes,U8 *data)
{
  CI386ModuleBinding binding;
  U8 *image;
  I64 image_bytes;
  I64 (*entry)(I64 value);
  binding.name="DurableData";
  binding.kind=I386_MODULE_DATA_EXPORT;
  binding.address=(data+0)(U64);
  if(!I386ModuleValid(module,module_bytes) ||
      I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableLater",0,0)) KernelStop;
  image_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableLater",&binding,1);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes)) ||
      I386LoadBoundInto(&module,&module_bytes,1,image,image_bytes,
        "DurableLater",&binding,1)!=image_bytes) KernelStop;
  entry=image;
  if(*data(I64 *)!=20 || (*entry)(22)!=42) KernelStop;
  *data(I64 *)=21;
  if((*entry)(22)!=43) KernelStop;
  *data(I64 *)=20;
  if(!I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramData(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function[1];
  CHashGlblVar *global;
  U8 *module,*disk_module;
  I64 module_bytes,disk_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  function[0]=ProbeSymbolFind(0,"DurableLater",table,HTT_FUN);
  global=ProbeSymbolFind(0,"DurableData",table,HTT_GLBL_VAR);
  if(!function[0] || !global || !global->data_addr ||
      !(module_bytes=probe->compiler->program_pack(symbols,function,1,0,0)) ||
      !(module=I386HeapAlloc(heap,module_bytes)) ||
      probe->compiler->program_pack(symbols,function,1,module,module_bytes)!=module_bytes)
    KernelStop;
  image_bytes=ProbeProgramDataRun(heap,module,module_bytes,global->data_addr);
  if(probe->persist_modules) {
    disk_module=probe->files->read(heap,"C:/Probe/DurableDataRead.t32m",&disk_bytes,0,0);
    if(disk_module) {
      if(ProbeProgramDataRun(heap,disk_module,disk_bytes,global->data_addr)!=image_bytes ||
          !I386HeapFree(heap,disk_module)) KernelStop;
      KernelLog("NATIVE DATA BOUND EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurableDataRead.t32m",module,module_bytes,0)) KernelStop;
    disk_module=probe->files->read(heap,"C:/Probe/DurableDataRead.t32m",&disk_bytes,0,0);
    if(!disk_module || disk_bytes!=module_bytes) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk_module[i]!=module[i]) KernelStop;
    if(ProbeProgramDataRun(heap,disk_module,disk_bytes,global->data_addr)!=image_bytes ||
        !I386HeapFree(heap,disk_module)) KernelStop;
    KernelLog("NATIVE DATA BOUND DISK\n");
  }
  if(!I386HeapFree(heap,module) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE DATA BOUND "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(module_bytes); KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramDataOwnedRun(CI386Heap *heap,U8 *module,I64 module_bytes)
{
  CI386ModuleHeader *header=module;
  CI386ModuleRecord *records,*record;
  U8 *image,*data;
  I64 image_bytes,data_offset=-1,i;
  I64 (*entry)(I64 value);
  if(!I386ModuleValid(module,module_bytes)) KernelStop;
  records=module+header->records_offset;
  for(i=0;i<header->record_count;i++) {
    record=records+i;
    if(record->kind==I386_MODULE_DATA_EXPORT &&
        !StrCmp(module+record->name_offset,"DurableData")) {
      if(data_offset>=0) KernelStop;
      data_offset=record->offset;
    }
  }
  if(data_offset<0) KernelStop;
  image_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableLater",0,0);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes)) ||
      I386LoadBoundInto(&module,&module_bytes,1,image,image_bytes,
        "DurableLater",0,0)!=image_bytes) KernelStop;
  data=image+8+data_offset;
  entry=image;
  if(*data(I64 *)!=20 || (*entry)(22)!=42) KernelStop;
  *data(I64 *)=21;
  if((*entry)(22)!=43 || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramDataOwned(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function[1];
  CHashGlblVar *globals[1];
  U8 *module,*disk_module;
  I64 module_bytes,disk_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  function[0]=ProbeSymbolFind(0,"DurableLater",table,HTT_FUN);
  globals[0]=ProbeSymbolFind(0,"DurableData",table,HTT_GLBL_VAR);
  if(!function[0] || !globals[0] ||
      !(module_bytes=probe->compiler->program_pack_data(symbols,function,1,globals,1,0,0)) ||
      !(module=I386HeapAlloc(heap,module_bytes))) KernelStop;
  module[0]=0xA5;
  if(probe->compiler->program_pack_data(symbols,function,1,globals,1,module,module_bytes-1) ||
      module[0]!=0xA5 ||
      probe->compiler->program_pack_data(symbols,function,1,globals,1,module,
        module_bytes)!=module_bytes) KernelStop;
  image_bytes=ProbeProgramDataOwnedRun(heap,module,module_bytes);
  if(probe->persist_modules) {
    disk_module=probe->files->read(heap,"C:/Probe/DurableOwned.t32m",&disk_bytes,0,0);
    if(disk_module) {
      if(ProbeProgramDataOwnedRun(heap,disk_module,disk_bytes)!=image_bytes ||
          !I386HeapFree(heap,disk_module)) KernelStop;
      KernelLog("NATIVE DATA OWNED EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurableOwned.t32m",module,module_bytes,0)) KernelStop;
    disk_module=probe->files->read(heap,"C:/Probe/DurableOwned.t32m",&disk_bytes,0,0);
    if(!disk_module || disk_bytes!=module_bytes) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk_module[i]!=module[i]) KernelStop;
    if(ProbeProgramDataOwnedRun(heap,disk_module,disk_bytes)!=image_bytes ||
        !I386HeapFree(heap,disk_module)) KernelStop;
    KernelLog("NATIVE DATA OWNED DISK\n");
  }
  if(!I386HeapFree(heap,module) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE DATA OWNED "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(module_bytes); KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramAggregateRun(CI386Heap *heap,U8 *module,I64 module_bytes)
{
  CI386ModuleHeader *header=module;
  CI386ModuleRecord *records,*record;
  U8 *image;
  I64 image_bytes,data_offset=-1,i,*pair;
  I64 (*entry)();
  if(!I386ModuleValid(module,module_bytes)) KernelStop;
  records=module+header->records_offset;
  for(i=0;i<header->record_count;i++) {
    record=records+i;
    if(record->kind==I386_MODULE_DATA_EXPORT &&
        !StrCmp(module+record->name_offset,"DurablePairData")) {
      if(data_offset>=0) KernelStop;
      data_offset=record->offset;
    }
  }
  if(data_offset<0) KernelStop;
  image_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurablePairSum",0,0);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes)) ||
      I386LoadBoundInto(&module,&module_bytes,1,image,image_bytes,
        "DurablePairSum",0,0)!=image_bytes) KernelStop;
  pair=image+8+data_offset; entry=image;
  if(pair[0]!=20 || pair[1]!=22 || (*entry)()!=42) KernelStop;
  pair[1]=23;
  if((*entry)()!=43 || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramAggregate(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function[1];
  CHashGlblVar *globals[1];
  U8 *module,*disk_module;
  I64 module_bytes,disk_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  function[0]=ProbeSymbolFind(0,"DurablePairSum",table,HTT_FUN);
  globals[0]=ProbeSymbolFind(0,"DurablePairData",table,HTT_GLBL_VAR);
  if(!function[0] || !globals[0] || globals[0]->size!=16 ||
      !(module_bytes=probe->compiler->program_pack_data(symbols,function,1,globals,1,0,0)) ||
      !(module=I386HeapAlloc(heap,module_bytes))) KernelStop;
  module[0]=0xA5;
  if(probe->compiler->program_pack_data(symbols,function,1,globals,1,module,module_bytes-1) ||
      module[0]!=0xA5 ||
      probe->compiler->program_pack_data(symbols,function,1,globals,1,module,
        module_bytes)!=module_bytes) KernelStop;
  image_bytes=ProbeProgramAggregateRun(heap,module,module_bytes);
  if(probe->persist_modules) {
    disk_module=probe->files->read(heap,"C:/Probe/DurableAggregate.t32m",&disk_bytes,0,0);
    if(disk_module) {
      if(ProbeProgramAggregateRun(heap,disk_module,disk_bytes)!=image_bytes ||
          !I386HeapFree(heap,disk_module)) KernelStop;
      KernelLog("NATIVE AGGREGATE EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurableAggregate.t32m",module,module_bytes,0)) KernelStop;
    disk_module=probe->files->read(heap,"C:/Probe/DurableAggregate.t32m",&disk_bytes,0,0);
    if(!disk_module || disk_bytes!=module_bytes) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk_module[i]!=module[i]) KernelStop;
    if(ProbeProgramAggregateRun(heap,disk_module,disk_bytes)!=image_bytes ||
        !I386HeapFree(heap,disk_module)) KernelStop;
    KernelLog("NATIVE AGGREGATE DISK\n");
  }
  if(!I386HeapFree(heap,module) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE AGGREGATE "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(module_bytes); KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramPointerRun(CI386Heap *heap,U8 *module,I64 module_bytes)
{
  CI386ModuleHeader *header=module;
  CI386ModuleRecord *records,*record;
  U8 *image,*bytes,*pointer;
  I64 image_bytes,bytes_offset=-1,pointer_offset=-1,i;
  I64 (*entry)();
  if(!I386ModuleValid(module,module_bytes) ||
      header->version!=I386_MODULE_POINTER_VERSION) KernelStop;
  records=module+header->records_offset;
  for(i=0;i<header->record_count;i++) {
    record=records+i;
    if(record->kind==I386_MODULE_DATA_EXPORT) {
      if(!StrCmp(module+record->name_offset,"DurableBytes")) bytes_offset=record->offset;
      if(!StrCmp(module+record->name_offset,"DurableBytesPtr")) pointer_offset=record->offset;
    }
  }
  if(bytes_offset<0 || pointer_offset<0) KernelStop;
  image_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"DurableByteRead",0,0);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes)) ||
      I386LoadBoundInto(&module,&module_bytes,1,image,image_bytes,
        "DurableByteRead",0,0)!=image_bytes) KernelStop;
  bytes=image+8+bytes_offset; pointer=image+8+pointer_offset; entry=image;
  if(bytes[0]!='a' || bytes[1]!='b' || bytes[2]!='c' || bytes[3] ||
      pointer(U8 **)[0]!=bytes || (*entry)()!=98) KernelStop;
  bytes[1]='Z';
  if((*entry)()!=90 || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramPointer(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function[1];
  CHashGlblVar *globals[2];
  U8 *module,*disk_module;
  I64 module_bytes,disk_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  function[0]=ProbeSymbolFind(0,"DurableByteRead",table,HTT_FUN);
  globals[0]=ProbeSymbolFind(0,"DurableBytes",table,HTT_GLBL_VAR);
  globals[1]=ProbeSymbolFind(0,"DurableBytesPtr",table,HTT_GLBL_VAR);
  if(!function[0] || !globals[0] || !globals[1] || globals[0]->size!=4 ||
      globals[1]->size!=4) KernelStop;
  if(!(module_bytes=probe->compiler->program_pack_data(symbols,function,1,globals,2,0,0)) ||
      !(module=I386HeapAlloc(heap,module_bytes))) KernelStop;
  module[0]=0xA5;
  if(probe->compiler->program_pack_data(symbols,function,1,globals,2,module,module_bytes-1) ||
      module[0]!=0xA5 ||
      probe->compiler->program_pack_data(symbols,function,1,globals,2,module,
        module_bytes)!=module_bytes) KernelStop;
  image_bytes=ProbeProgramPointerRun(heap,module,module_bytes);
  if(probe->persist_modules) {
    disk_module=probe->files->read(heap,"C:/Probe/DurablePointer.t32m",&disk_bytes,0,0);
    if(disk_module) {
      if(ProbeProgramPointerRun(heap,disk_module,disk_bytes)!=image_bytes ||
          !I386HeapFree(heap,disk_module)) KernelStop;
      KernelLog("NATIVE POINTER EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurablePointer.t32m",module,module_bytes,0)) KernelStop;
    disk_module=probe->files->read(heap,"C:/Probe/DurablePointer.t32m",&disk_bytes,0,0);
    if(!disk_module || disk_bytes!=module_bytes) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk_module[i]!=module[i]) KernelStop;
    if(ProbeProgramPointerRun(heap,disk_module,disk_bytes)!=image_bytes ||
        !I386HeapFree(heap,disk_module)) KernelStop;
    KernelLog("NATIVE POINTER DISK\n");
  }
  if(!I386HeapFree(heap,module) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE POINTER "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(module_bytes); KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramNamedPointerRun(CI386Heap *heap,U8 **modules,I64 *sizes)
{
  CI386ModuleHeader *consumer=modules[0],*provider=modules[1];
  CI386ModuleRecord *record;
  U8 *image,*bytes,*pointer;
  I64 i,bytes_offset=-1,pointer_offset=-1,image_bytes;
  I64 (*entry)();
  if(!I386ModuleValid(modules[0],sizes[0]) ||
      !I386ModuleValid(modules[1],sizes[1]) ||
      consumer->version!=I386_MODULE_NAMED_POINTER_VERSION ||
      I386LoadBoundInto(modules,sizes,1,0,0,"DurableByteRead",0,0)) KernelStop;
  record=modules[0]+consumer->records_offset;
  for(i=0;i<consumer->record_count;i++,record++)
    if(record->kind==I386_MODULE_DATA_EXPORT &&
        !StrCmp(modules[0]+record->name_offset,"DurableBytesPtr"))
      pointer_offset=record->offset;
  record=modules[1]+provider->records_offset;
  for(i=0;i<provider->record_count;i++,record++)
    if(record->kind==I386_MODULE_DATA_EXPORT &&
        !StrCmp(modules[1]+record->name_offset,"DurableBytes"))
      bytes_offset=record->offset;
  if(bytes_offset<0 || pointer_offset<0) KernelStop;
  image_bytes=I386LoadBoundInto(modules,sizes,2,0,0,"DurableByteRead",0,0);
  if(image_bytes<1 || !(image=I386HeapAlloc(heap,image_bytes)) ||
      I386LoadBoundInto(modules,sizes,2,image,image_bytes,
        "DurableByteRead",0,0)!=image_bytes) KernelStop;
  pointer=image+8+pointer_offset;
  bytes=image+8+consumer->code_size+bytes_offset; entry=image;
  if(pointer(U8 **)[0]!=bytes || bytes[1]!='b' || (*entry)()!=98) KernelStop;
  bytes[1]='Z';
  if((*entry)()!=90 || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramNamedPointer(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *function[1];
  CHashGlblVar *globals[1];
  U8 *modules[2],*disk[2],*paths[2];
  I64 sizes[2],disk_sizes[2],image_bytes,i,j;
  I64 used=heap->used,allocations=heap->allocations;
  paths[0]="C:/Probe/DurableNamedConsumer.t32m";
  paths[1]="C:/Probe/DurableNamedProvider.t32m";
  function[0]=ProbeSymbolFind(0,"DurableByteRead",table,HTT_FUN);
  globals[0]=ProbeSymbolFind(0,"DurableBytesPtr",table,HTT_GLBL_VAR);
  if(!function[0] || !globals[0] ||
      !(sizes[0]=probe->compiler->program_pack_data(symbols,function,1,globals,1,0,0)) ||
      !(modules[0]=I386HeapAlloc(heap,sizes[0])) ||
      probe->compiler->program_pack_data(symbols,function,1,globals,1,
        modules[0],sizes[0])!=sizes[0]) KernelStop;
  function[0]=ProbeSymbolFind(0,"DurableConst",table,HTT_FUN);
  globals[0]=ProbeSymbolFind(0,"DurableBytes",table,HTT_GLBL_VAR);
  if(!function[0] || !globals[0] ||
      !(sizes[1]=probe->compiler->program_pack_data(symbols,function,1,globals,1,0,0)) ||
      !(modules[1]=I386HeapAlloc(heap,sizes[1])) ||
      probe->compiler->program_pack_data(symbols,function,1,globals,1,
        modules[1],sizes[1])!=sizes[1]) KernelStop;
  image_bytes=ProbeProgramNamedPointerRun(heap,modules,sizes);
  if(probe->persist_modules) {
    for(i=0;i<2;i++) disk[i]=probe->files->read(heap,paths[i],&disk_sizes[i],0,0);
    if(disk[0] && disk[1]) {
      if(ProbeProgramNamedPointerRun(heap,disk,disk_sizes)!=image_bytes) KernelStop;
      KernelLog("NATIVE NAMED POINTER EXISTING\n");
    } else if(disk[0] || disk[1]) KernelStop;
    for(i=0;i<2;i++) {
      if(disk[i] && !I386HeapFree(heap,disk[i]) ||
          !probe->files->write(paths[i],modules[i],sizes[i],0)) KernelStop;
      disk[i]=probe->files->read(heap,paths[i],&disk_sizes[i],0,0);
      if(!disk[i] || disk_sizes[i]!=sizes[i]) KernelStop;
      for(j=0;j<sizes[i];j++) if(disk[i][j]!=modules[i][j]) KernelStop;
    }
    if(ProbeProgramNamedPointerRun(heap,disk,disk_sizes)!=image_bytes) KernelStop;
    for(i=0;i<2;i++) if(!I386HeapFree(heap,disk[i])) KernelStop;
    KernelLog("NATIVE NAMED POINTER DISK\n");
  }
  for(i=0;i<2;i++) if(!I386HeapFree(heap,modules[i])) KernelStop;
  if(heap->used!=used || heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE NAMED POINTER "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(sizes[0]); KernelLog(" "); KernelHex(sizes[1]); KernelLog(" ");
  KernelHex(image_bytes); KernelLog("\n");
}
U0 ProbeProgramMulti(CI386CompilerProbe *probe,CI386Heap *heap,
  CPrsSymbolServices *symbols,CHashTable *table)
{
  CHashFun *functions[3];
  U8 *module,*disk_module=0;
  I64 module_bytes,disk_bytes,image_bytes,text_bytes,*data_start,i;
  I64 used=heap->used,allocations=heap->allocations;
  functions[0]=ProbeSymbolFind(0,"DurableLeaf",table,HTT_FUN);
  functions[1]=ProbeSymbolFind(0,"DurableRoot",table,HTT_FUN);
  functions[2]=ProbeSymbolFind(0,"DurableText",table,HTT_FUN);
  if(!functions[0] || !functions[1] || !functions[2] ||
      !probe->compiler->code_span(symbols,functions[2]->exe_addr,&text_bytes,&data_start) ||
      *data_start<1 || *data_start>=text_bytes ||
      !(module_bytes=probe->compiler->program_pack(symbols,functions,3,0,0)) ||
      !(module=I386HeapAlloc(heap,module_bytes))) KernelStop;
  module[0]=0xA5;
  if(probe->compiler->program_pack(symbols,functions,3,module,module_bytes-1) ||
      module[0]!=0xA5 || probe->compiler->program_pack(symbols,functions,3,module,
        module_bytes)!=module_bytes) KernelStop;
  image_bytes=ProbeProgramMultiRun(heap,module,module_bytes);
  if(probe->persist_modules) {
    disk_module=probe->files->read(heap,"C:/Probe/DurablePair.t32m",&disk_bytes,0,0);
    if(disk_module) {
      if(ProbeProgramMultiRun(heap,disk_module,disk_bytes)!=image_bytes ||
          !I386HeapFree(heap,disk_module)) KernelStop;
      disk_module=0;
      KernelLog("NATIVE MULTI EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurablePair.t32m",module,module_bytes,0)) KernelStop;
    disk_module=probe->files->read(heap,"C:/Probe/DurablePair.t32m",&disk_bytes,0,0);
    if(!disk_module || disk_bytes!=module_bytes) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk_module[i]!=module[i]) KernelStop;
    if(ProbeProgramMultiRun(heap,disk_module,disk_bytes)!=image_bytes ||
        !I386HeapFree(heap,disk_module)) KernelStop;
    KernelLog("NATIVE MULTI DISK\n");
  }
  if(!I386HeapFree(heap,module) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE MULTI "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(module_bytes); KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
I64 ProbeProgramUnitRun(CI386Heap *heap,U8 *module,I64 module_bytes)
{
  CI386ModuleHeader *header=module;
  CI386ModuleRecord *record;
  U8 *image;
  I64 i,base_offset=-1,image_bytes;
  I64 (*entry)();
  if(!I386ModuleValid(module,module_bytes) || header->version!=I386_MODULE_VERSION)
    KernelStop;
  record=module+header->records_offset;
  for(i=0;i<header->record_count;i++,record++)
    if(record->kind==I386_MODULE_DATA_EXPORT &&
        !StrCmp(module+record->name_offset,"UnitBase")) base_offset=record->offset;
  if(base_offset<0) KernelStop;
  image_bytes=I386LoadBoundInto(&module,&module_bytes,1,0,0,"UnitMain",0,0);
  image=I386HeapAlloc(heap,image_bytes);
  if(!image || I386LoadBoundInto(&module,&module_bytes,1,image,image_bytes,
      "UnitMain",0,0)!=image_bytes) KernelStop;
  entry=image;
  if((*entry)()!=42 || (image+8+base_offset)(I64 *)[0]!=20) KernelStop;
  (image+8+base_offset)(I64 *)[0]=21;
  if((*entry)()!=43 || !I386HeapFree(heap,image)) KernelStop;
  return image_bytes;
}
U0 ProbeProgramUnit(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CCmpCtrl *cc;
  CPrsSymbolServices *symbols;
  U8 *module=0,*disk=0;
  I64 module_bytes,disk_bytes,image_bytes,i;
  I64 used=heap->used,allocations=heap->allocations;
  cc=probe->files->control_new(
    "I64i UnitBase=20;"
    "I64i UnitAdd(I64i x){return UnitBase+x;}"
    "I64i UnitMain(){return UnitAdd(22);}",
    CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Unit.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0) ||
      !(symbols=probe->compiler->frontend(heap,cc,probe->internal_types,
        probe->disk_include))) KernelStop;
  ProbeProgramRead(probe,heap,cc,symbols);
  module_bytes=probe->compiler->program_pack_unit(symbols,0,0);
  module=I386HeapAlloc(heap,module_bytes);
  if(module_bytes<1 || !module ||
      probe->compiler->program_pack_unit(symbols,module,module_bytes)!=module_bytes ||
      !I386ModuleValid(module,module_bytes) ||
      !probe->compiler->control_unwind(I386TaskSelf,outer)) KernelStop;
  image_bytes=ProbeProgramUnitRun(heap,module,module_bytes);
  if(probe->persist_modules) {
    disk=probe->files->read(heap,"C:/Probe/DurableUnit.t32m",&disk_bytes,0,0);
    if(disk) {
      if(ProbeProgramUnitRun(heap,disk,disk_bytes)!=image_bytes ||
          !I386HeapFree(heap,disk)) KernelStop;
      KernelLog("NATIVE UNIT EXISTING\n");
    }
    if(!probe->files->write("C:/Probe/DurableUnit.t32m",module,module_bytes,0)) KernelStop;
    disk=probe->files->read(heap,"C:/Probe/DurableUnit.t32m",&disk_bytes,0,0);
    if(!disk || disk_bytes!=module_bytes) KernelStop;
    for(i=0;i<module_bytes;i++) if(disk[i]!=module[i]) KernelStop;
    if(ProbeProgramUnitRun(heap,disk,disk_bytes)!=image_bytes ||
        !I386HeapFree(heap,disk)) KernelStop;
    KernelLog("NATIVE UNIT DISK\n");
  }
  if(!I386HeapFree(heap,module) || heap->used!=used ||
      heap->allocations!=allocations) KernelStop;
  KernelLog("NATIVE UNIT "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(module_bytes); KernelLog(" "); KernelHex(image_bytes); KernelLog("\n");
}
U0 ProbePrograms(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskStorage *old_storage=scope->storage,*storage;
  CCmpCtrl *cc,*failed;
  CPrsSymbolServices *symbols,*failed_symbols;
  CHashSrcSym *roots[32],*entry;
  CHashFun *fun,*static_fun;
  CHashGlblVar *alias;
  CHashClass *collision;
  CHashTable *source_table,*parent_table;
  CMemberLst *member;
  U8 *source,*old_index,*old_code,*old_static,*literal,*block,*fill,*next,*name;
  I64 *generated_split;
  I64 kind,count,i,j,before_used,before_allocations,generated_bytes,old_data_start=0;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 irq,flags=GetRFlags;
  Bool result,recovered;
  for(kind=0;kind<14;kind++) {
    source="I64i DurableData=20;"
      "class DurablePair{I64i a,b;};DurablePair DurablePairData={20,22};"
      "I64i DurablePairSum(){return DurablePairData.a+DurablePairData.b;}"
      "U8i DurableBytes[4]=\"abc\";U8i *DurableBytesPtr=DurableBytes;"
      "I64i DurableByteRead(){return DurableBytesPtr[1];}"
      "extern I64i DurableLater(I64i x);"
      "I64i DurableAdd(I64i x=22){return DurableLater(x);}"
      "I64i DurableLater(I64i x){return DurableData+x;}"
      "I64i DurableNext(){static I64i n=40;return ++n;}"
      "I64i DurableFact(I64i n){if(n<2)return 1;return n*DurableFact(n-1);}"
      "I64i DurableDefault(U8i *s=\"xy\"){return s[1];}"
      "U8i *DurableText(){return \"hello\";}"
      "U8i *DurableLiteral=0;DurableLiteral=(\"hello\");"
      "U8i *DurableInit=\"abc\";"
      "I64i DurableString(){static U8i *p=\"def\";return ++p[0];}"
      "I64i DurableConst(){return 42;}"
      "I64i DurableLeaf(){return 41;}"
      "I64i DurableRoot(){return DurableLeaf()+1;}"
      "U8i *DurableAddress(){return &DurableLeaf;}"
      "U8i DurableZero;";
    if(kind==7) source="extern I64i Future();I64i Caller(){return Future();}";
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Program.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols) KernelStop;
    KernelLog("PROGRAM START "); KernelHex(kind); KernelLog("\n");
    literal=ProbeProgramRead(probe,heap,cc,symbols);
    if(kind!=7) {
      //Model a system-symbol alias after address resolution. The native system
      //symbol linker is separate; exercise publication without reading address 0.
      alias=ProbeSymbolFind(0,"DurableZero",cc->htc.glbl_hash_table,HTT_GLBL_VAR);
      if(!alias || !alias->data_addr) KernelStop;
      symbols->declarations->release(symbols->declarations->context,alias->data_addr);
      alias->data_addr=0; alias->flags|=GVF_ALIAS;
    }
    source_table=cc->htc.glbl_hash_table; count=0; collision=0; fill=0;
    for(i=0;i<=source_table->mask;i++)
      for(entry=source_table->body[i];entry;entry=entry->next) {
        if(count>=32) KernelStop;
        roots[count++]=entry;
      }
    fun=ProbeSymbolFind(0,"DurableAdd",source_table,HTT_FUN);
    if(kind!=7 && (!probe->compiler->code_span(symbols,fun->exe_addr,&generated_bytes,&generated_split) ||
        *generated_split<1 || *generated_split>generated_bytes)) KernelStop;
    if(kind!=7) old_data_start=*generated_split;
    static_fun=ProbeSymbolFind(0,"DurableNext",source_table,HTT_FUN);
    member=0; old_index=0; old_code=0; old_static=0;
    if(kind!=7) {
      if(!fun || !static_fun || !literal) KernelStop;
      old_index=fun->idx; old_code=fun->exe_addr;
      member=static_fun->member_lst_and_root;
      if(!member || !(member->flags&MLF_STATIC)) KernelStop;
      old_static=member->static_data;
    }
    switch(kind) {
      case 1:
        collision=I386HeapAlloc(heap,sizeof(CHashClass)*(PTR_STARS_NUM+1),TRUE);
        name=I386HeapAlloc(heap,12,FALSE);
        if(!collision || !name) KernelStop;
        PrsClassInit(collision); source="DurableData";
        for(i=0;i<12;i++) name[i]=source[i];
        collision->str=name; HashAdd(collision,task->hash_table); break;
      case 2: fun->idx="Foreign"; break;
      case 3: fun->idx=fun->str; break;
      case 4:
        for(j=65536;j>=8;j=j/2)
          while(block=I386HeapAlloc(heap,j,FALSE)) { block(U8 **)[0]=fill; fill=block; }
        break;
      case 5:
        if(!probe->compiler->code_add(heap,cc,IC_IMM_I64,1,probe->internal_types[RT_I64],0)) KernelStop;
        break;
      case 6: cc->error_cnt=1; break;
      case 8: fun->exe_addr="Foreign"; break;
      case 9: member->static_data=fun->str; break;
      case 12: *generated_split=0; break;
      case 13: *generated_split=generated_bytes+1; break;
    }
    if(kind==10) {
      ProbeProgramModule(probe,heap,symbols,source_table);
      ProbeProgramRelocation(probe,heap,symbols,source_table);
      ProbeProgramMulti(probe,heap,symbols,source_table);
      ProbeProgramBound(probe,heap,symbols,source_table);
      ProbeProgramSplit(probe,heap,symbols,source_table);
      ProbeProgramAddress(probe,heap,symbols,source_table);
      ProbeProgramData(probe,heap,symbols,source_table);
      ProbeProgramDataOwned(probe,heap,symbols,source_table);
      ProbeProgramAggregate(probe,heap,symbols,source_table);
      ProbeProgramPointer(probe,heap,symbols,source_table);
      ProbeProgramNamedPointer(probe,heap,symbols,source_table);
      fun=ProbeSymbolFind(0,"DurableNext",source_table,HTT_FUN);
      if(!fun || probe->compiler->program_pack_data(symbols,&fun,1,0,0,0,0)) KernelStop;
      ProbeProgramJitSpan(probe,symbols,source_table,"DurableAdd",probe->phase,0);
      ProbeProgramJitSpan(probe,symbols,source_table,"DurableFact",probe->phase,1);
      ProbeProgramJitSpan(probe,symbols,source_table,"DurableDefault",probe->phase,2);
      ProbeProgramJitSpan(probe,symbols,source_table,"DurableText",probe->phase,3);
      ProbeProgramJitSpan(probe,symbols,source_table,"DurableNext",probe->phase,4);
      ProbeProgramJitSpan(probe,symbols,source_table,"DurableString",probe->phase,5);
    }
    before_used=heap->used; before_allocations=heap->allocations;
    if(!kind) {
      //A missing parent must not match an absent private macro table.
      parent_table=source_table->next; source_table->next=0;
      if(probe->compiler->publish(heap,cc,symbols) || heap->used!=before_used ||
          heap->allocations!=before_allocations || scope->storage!=old_storage) KernelStop;
      for(i=0;i<count;i++)
        if(ProbeSymbolFind(0,roots[i]->str,source_table,roots[i]->type)!=roots[i]) KernelStop;
      source_table->next=parent_table;
      KernelLog("PROGRAM PARENT REJECT "); KernelHex(probe->phase); KernelLog("\n");
    }
    result=probe->compiler->publish(heap,cc,symbols);
    if(result!=(!kind || kind==10 || kind==11)) KernelStop;
    if(!result) {
      if(heap->used!=before_used || heap->allocations!=before_allocations || scope->storage!=old_storage) KernelStop;
      for(i=0;i<count;i++) if(ProbeSymbolFind(0,roots[i]->str,source_table,roots[i]->type)!=roots[i]) KernelStop;
      if(kind!=7) { fun->idx=old_index; fun->exe_addr=old_code; member->static_data=old_static; }
      if(kind!=7) *generated_split=old_data_start;
      if(collision && (!ProbePublishedRemove(task->hash_table,collision) || !I386HashDel(heap,collision))) KernelStop;
      while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    } else {
      if(scope->storage==old_storage || scope->storage->next!=old_storage) KernelStop;
      if(kind==10) {
        storage=scope->storage; before_used=heap->used; before_allocations=heap->allocations;
        if(!probe->compiler->publish(heap,cc,symbols) || scope->storage!=storage ||
            heap->used!=before_used || heap->allocations!=before_allocations) KernelStop;
      }
      if(kind==11) {
        recovered=FALSE;
        try { symbols->declarations->execute(symbols->declarations->context,literal); }
        catch { if(task->except_ch=='Compiler') { task->catch_except=TRUE; recovered=TRUE; } }
        if(!recovered) KernelStop;
      }
    }
    if(!probe->compiler->control_unwind(task,outer)) KernelStop;
    if(result) {
      if(ProbeProgramUse(probe,heap,outer,"DurableAdd;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"DurableNext;")!=41 ||
          ProbeProgramUse(probe,heap,outer,"DurableFact(5);")!=120 ||
          ProbeProgramUse(probe,heap,outer,"DurablePairData.a+DurablePairData.b;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"DurableByteRead;")!=98 ||
          ProbeProgramUse(probe,heap,outer,"DurableDefault;")!=121 ||
          ProbeProgramUse(probe,heap,outer,"DurableInit[1];")!=98 ||
          ProbeProgramUse(probe,heap,outer,"DurableString;")!=101 ||
          ProbeProgramUse(probe,heap,outer,"DurableInit[0]=90;")!=90 ||
          ProbeProgramUse(probe,heap,outer,"&DurableZero;")!=0 ||
          ProbeProgramUse(probe,heap,outer,"(DurableText)[1]+DurableLiteral[1];")!=202) KernelStop;
      failed=probe->files->control_new("U8i *Fresh=\"lost\";Unknown bad;",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/ProgramFailure.HC");
      if(!failed || !probe->compiler->control_enter(heap,failed,0,0)) KernelStop;
      failed_symbols=probe->compiler->frontend(heap,failed,probe->internal_types,probe->disk_include);
      if(!failed_symbols) KernelStop;
      recovered=FALSE;
      try { ProbeProgramRead(probe,heap,failed,failed_symbols); }
      catch { if(task->except_ch=='Compiler') { task->catch_except=TRUE; recovered=TRUE; } }
      if(!recovered || probe->compiler->publish(heap,failed,failed_symbols) ||
          !probe->compiler->control_unwind(task,outer) || ProbeSymbolFind(0,"Fresh",task->hash_table,HTT_GLBL_VAR) ||
          ProbeProgramUse(probe,heap,outer,"DurableAdd;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"DurableNext;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"DurableInit[0]+DurableInit[2];")!=189 ||
          ProbeProgramUse(probe,heap,outer,"DurableString;")!=102) KernelStop;
      //The fixture has exclusive references. Remove its published roots and
      //storage; production teardown is covered separately by task-symbol tests.
      for(i=0;i<count;i++)
        if(!ProbePublishedRemove(task->hash_table,roots[i]) || !I386HashDel(heap,roots[i])) KernelStop;
      storage=scope->storage; scope->storage=storage->next;
      if(!I386TaskStorageRelease(heap,storage)) KernelStop;
    }
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        scope->storage!=old_storage || heap->used!=used || heap->allocations!=allocations ||
        !I386HeapValid(heap) || (GetRFlags&0x200)!=(flags&0x200)) { KernelLog("PROGRAM OWNERSHIP REJECT\n"); KernelStop; }
    KernelLog("PROGRAM CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
  ProbeProgramUnit(probe,heap,outer);
}
