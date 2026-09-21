I64 GraphicsAllocationCheck()
{
  I64 before=Fs->data_heap->used_u8s,caught=0;
  CDC *dc=NULL;
  try { dc=DCNew(640,I32_MAX); }
  catch { if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught++; } }
  if(dc) DCDel(dc);
  if(caught!=1 || Fs->data_heap->used_u8s!=before) return -1;
  dc=DCNew(8,8); DCDel(dc);
  if(Fs->data_heap->used_u8s!=before) return -2;
  return 2;
}
