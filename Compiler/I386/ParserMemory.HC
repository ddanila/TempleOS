//Included after native control ownership and release helpers.
#include "/Compiler/I386/ParserMemory.HH"
U8 *I386ParserAlloc(CI386Heap *heap,CCmpCtrl *cc,I64 bytes,Bool zeroed=TRUE)
{
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record;
  U8 *allocation;
  U32 irq=I386IrqSave;
  if(!I386CmpCodeOwner(heap,cc) || bytes<1 || bytes>0x7FFFFFFF) {
    I386IrqRestore(irq); return 0;
  }
  allocation=I386HeapAlloc(heap,bytes,zeroed);
  if(!allocation) { I386IrqRestore(irq); throw('OutMem',TRUE); }
  record=I386HeapAlloc(heap,sizeof(CI386ParserAllocation),TRUE);
  if(!record) {
    I386HeapFree(heap,allocation);
    I386IrqRestore(irq); throw('OutMem',TRUE);
  }
  record->allocation=allocation; record->next=&owned->parser_next;
  record->last=owned->parser_last; record->last->next=record; owned->parser_last=record;
  I386IrqRestore(irq); return allocation;
}
Bool I386ParserFree(CI386Heap *heap,CCmpCtrl *cc,U8 *allocation)
{
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record;
  CI386CmpRelease release;
  U32 irq=I386IrqSave;
  Bool found=FALSE;
  if(!I386CmpCodeOwner(heap,cc)) { I386IrqRestore(irq); return FALSE; }
  if(!allocation) { I386IrqRestore(irq); return TRUE; }
  for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
    if(record->allocation==allocation) { found=TRUE; break; }
  if(!found) { I386IrqRestore(irq); return FALSE; }
  release.heap=heap; release.control=cc; release.ok=TRUE;
  I386CmpReleaseAllocation(&release,allocation);
  I386IrqRestore(irq); return release.ok;
}
