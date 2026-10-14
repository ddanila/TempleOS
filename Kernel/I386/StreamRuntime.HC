//Compile-time source emission keeps every parser buffer control-owned.
U0 NativeStreamPrint(U8 *fmt,...)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope;
  CCmpCtrl *cc;
  CStreamBlk *block;
  U8 *text=0,*joined;
  I64 old_size,size,i;
  if(!console_config || !task || !(scope=task->symbol_state) || scope->task!=task ||
      !(cc=task->last_cc) || cc==&task->next_cc) throw('Compiler',TRUE);
  block=cc->last_stream_blk;
  if(block==&cc->next_stream_blk) {
    DocPrint(DocPut,"No exe{} blk\n"); return;
  }
  try {
    text=StrPrintJoin(NULL,fmt,argc,argv);
    if(!text) throw('OutMem',TRUE);
    old_size=StrLen(block->body); size=StrLen(text);
    if(old_size>0x7FFFFFFE-size) throw('OutMem',TRUE);
    joined=console_config->compiler->parser_alloc(scope->heap,cc,old_size+size+1,FALSE);
    if(!joined) throw('OutMem',TRUE);
    for(i=0;i<old_size;i++) joined[i]=block->body[i];
    for(i=0;i<=size;i++) joined[old_size+i]=text[i];
    if(!console_config->compiler->parser_free(scope->heap,cc,block->body)) throw('Compiler',TRUE);
    block->body=joined;
    Free(text); text=0;
  } catch { Free(text); throw; }
}
U0 NativeStreamDir()
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CLexFile *file;
  U8 *directory=0;
  if(!task || !(cc=task->last_cc) || cc==&task->next_cc) throw('Compiler',TRUE);
  file=cc->lex_include_stk;
  while(file && file->flags&LFSF_DEFINE && file->next) file=file->next;
  if(!file || !file->full_name) throw('Compiler',TRUE);
  try {
    directory=NativeDirPathParent(file->full_name);
    if(!directory) throw('OutMem',TRUE);
    NativeStreamPrint("\"%s\"",directory);
    Free(directory); directory=0;
  } catch { Free(directory); throw; }
}
