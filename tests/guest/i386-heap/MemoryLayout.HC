//Target layout from the captured original x64 records and 32-bit pointer policy.
#assert sizeof(CMemUnused)==12
#assert offset(CMemUnused.hc)==0
#assert offset(CMemUnused.caller1)==0
#assert offset(CMemUnused.caller2)==0
#assert offset(CMemUnused.next)==0
#assert offset(CMemUnused.size)==4
#assert sizeof(CMemUsed)==12
#assert offset(CMemUsed.hc)==0
#assert offset(CMemUsed.caller1)==4
#assert offset(CMemUsed.caller2)==4
#assert offset(CMemUsed.next)==4
#assert offset(CMemUsed.last)==4
#assert offset(CMemUsed.size)==4
#assert offset(CMemUsed.start)==12
#assert sizeof(CMemBlk)==16
#assert offset(CMemBlk.next)==0
#assert offset(CMemBlk.last)==4
#assert offset(CMemBlk.mb_signature)==8
#assert offset(CMemBlk.pags)==12
#assert sizeof(CMemRange)==28
#assert offset(CMemRange.next)==0
#assert offset(CMemRange.last)==4
#assert offset(CMemRange.type)==8
#assert offset(CMemRange.flags)==12
#assert offset(CMemRange.base)==16
#assert offset(CMemRange.size)==20
#assert sizeof(CBlkPool)==1276
#assert offset(CBlkPool.locked_flags)==0
#assert offset(CBlkPool.alloced_u8s)==8
#assert offset(CBlkPool.used_u8s)==16
#assert offset(CBlkPool.mem_free_lst)==24
#assert offset(CBlkPool.mem_free_2meg_lst)==28
#assert offset(CBlkPool.free_pag_hash)==32
#assert offset(CBlkPool.free_pag_hash2)==1056
#assert sizeof(CHeapCtrl)==1088
#assert offset(CHeapCtrl.bp)==0
#assert offset(CHeapCtrl.hc_signature)==4
#assert offset(CHeapCtrl.pad)==8
#assert offset(CHeapCtrl.locked_flags)==12
#assert offset(CHeapCtrl.alloced_u8s)==20
#assert offset(CHeapCtrl.used_u8s)==28
#assert offset(CHeapCtrl.mem_task)==36
#assert offset(CHeapCtrl.next_mem_blk)==40
#assert offset(CHeapCtrl.last_mem_blk)==44
#assert offset(CHeapCtrl.last_mergable)==48
#assert offset(CHeapCtrl.malloc_free_lst)==52
#assert offset(CHeapCtrl.next_um)==56
#assert offset(CHeapCtrl.last_um)==60
#assert offset(CHeapCtrl.heap_hash)==64
Bool MemoryLayoutCheck()
{
  if(sizeof(CMemUnused)!=12) return FALSE;
  if(offset(CMemUnused.hc)!=0) return FALSE;
  if(offset(CMemUnused.caller1)!=0) return FALSE;
  if(offset(CMemUnused.caller2)!=0) return FALSE;
  if(offset(CMemUnused.next)!=0) return FALSE;
  if(offset(CMemUnused.size)!=4) return FALSE;
  if(sizeof(CMemUsed)!=12) return FALSE;
  if(offset(CMemUsed.hc)!=0) return FALSE;
  if(offset(CMemUsed.caller1)!=4) return FALSE;
  if(offset(CMemUsed.caller2)!=4) return FALSE;
  if(offset(CMemUsed.next)!=4) return FALSE;
  if(offset(CMemUsed.last)!=4) return FALSE;
  if(offset(CMemUsed.size)!=4) return FALSE;
  if(offset(CMemUsed.start)!=12) return FALSE;
  if(sizeof(CMemBlk)!=16) return FALSE;
  if(offset(CMemBlk.next)!=0) return FALSE;
  if(offset(CMemBlk.last)!=4) return FALSE;
  if(offset(CMemBlk.mb_signature)!=8) return FALSE;
  if(offset(CMemBlk.pags)!=12) return FALSE;
  if(sizeof(CMemRange)!=28) return FALSE;
  if(offset(CMemRange.next)!=0) return FALSE;
  if(offset(CMemRange.last)!=4) return FALSE;
  if(offset(CMemRange.type)!=8) return FALSE;
  if(offset(CMemRange.flags)!=12) return FALSE;
  if(offset(CMemRange.base)!=16) return FALSE;
  if(offset(CMemRange.size)!=20) return FALSE;
  if(sizeof(CBlkPool)!=1276) return FALSE;
  if(offset(CBlkPool.locked_flags)!=0) return FALSE;
  if(offset(CBlkPool.alloced_u8s)!=8) return FALSE;
  if(offset(CBlkPool.used_u8s)!=16) return FALSE;
  if(offset(CBlkPool.mem_free_lst)!=24) return FALSE;
  if(offset(CBlkPool.mem_free_2meg_lst)!=28) return FALSE;
  if(offset(CBlkPool.free_pag_hash)!=32) return FALSE;
  if(offset(CBlkPool.free_pag_hash2)!=1056) return FALSE;
  if(sizeof(CHeapCtrl)!=1088) return FALSE;
  if(offset(CHeapCtrl.bp)!=0) return FALSE;
  if(offset(CHeapCtrl.hc_signature)!=4) return FALSE;
  if(offset(CHeapCtrl.pad)!=8) return FALSE;
  if(offset(CHeapCtrl.locked_flags)!=12) return FALSE;
  if(offset(CHeapCtrl.alloced_u8s)!=20) return FALSE;
  if(offset(CHeapCtrl.used_u8s)!=28) return FALSE;
  if(offset(CHeapCtrl.mem_task)!=36) return FALSE;
  if(offset(CHeapCtrl.next_mem_blk)!=40) return FALSE;
  if(offset(CHeapCtrl.last_mem_blk)!=44) return FALSE;
  if(offset(CHeapCtrl.last_mergable)!=48) return FALSE;
  if(offset(CHeapCtrl.malloc_free_lst)!=52) return FALSE;
  if(offset(CHeapCtrl.next_um)!=56) return FALSE;
  if(offset(CHeapCtrl.last_um)!=60) return FALSE;
  if(offset(CHeapCtrl.heap_hash)!=64) return FALSE;
  return TRUE;
}
