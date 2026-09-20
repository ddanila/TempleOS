//Boot-only storage/lexer diagnostics, released with CompilerProbe.
U0 ProbeStorage(CI386CompilerProbe *probe)
{
  CI386Heap *heap=probe->heap;
  U8 *buffer,empty[1];
  CCmpCtrl *cc;
  CLexFile *file;
  I64 size=0,i,ch,characters=0,lines=0,used=heap->used,allocations=heap->allocations,transient;
  U32 hash=2166136261,lex_hash=2166136261;
  if(probe->phase || GetRFlags&0x200) KernelStop;
  buffer=(*probe->source_read)(probe->volume,heap,probe->volume->root,"/Kernel/I386/Kernel.HC",&size);
  cc=I386HeapAlloc(heap,sizeof(CCmpCtrl),TRUE);
  if(!buffer || !cc || size<1) KernelStop;
  for(i=0;i<size;i++) hash=(hash^buffer[i])*16777619;
  KernelLog("SOURCE "); KernelHex(size); KernelLog(" ");
  KernelHex(hash); KernelLog("\n");
  empty[0]=0;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF,0,char_bmp_alpha_numeric);
  file=I386LexFilePush(heap,cc);
  if(!file) KernelStop;
  LexFileSeed(file,empty); cc->cur_buf_ptr=empty;
  if(!I386LexIncludeTake(heap,cc,"/Kernel/I386/Kernel.HC",buffer)) KernelStop;
  transient=heap->used-used;
  while(ch=I386LexRawChar(heap,cc,&lines)) {
    if(ch<0 || cc->lex_include_stk==file || cc->lex_include_stk->line_num!=lines+1) KernelStop;
    lex_hash=(lex_hash^ch)*16777619; characters++;
  }
  if(cc->lex_include_stk!=file || cc->cur_buf_ptr!=empty || file->line_num!=1 ||
      I386HeapSize(heap,buffer)!=-1 || heap->allocations!=allocations+2) KernelStop;
  if(!(*probe->source_pop)(heap,cc,0,0) || !I386HeapFree(heap,cc) ||
      heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
  KernelLog("LEX_SOURCE "); KernelHex(characters); KernelLog(" "); KernelHex(lines); KernelLog(" ");
  KernelHex(lex_hash); KernelLog(" "); KernelHex(transient); KernelLog("\n");
}
