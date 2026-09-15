#include "/Kernel/I386/Memory.HH"
#include "/Kernel/I386/Cpu.HH"
//Single CPU, no NMI callers. All list/counter mutations run with IRQs masked.
//This is the internal allocation core; public MAlloc/OutMem and task binding
//must be supplied by the retained memory service before application exposure.
Bool I386MemPoolValid(CI386PublicPool *pool)
{
  CI386PoolRegion *region,*last=0;
  U64 total=0,used=0,base;
  U32 count=0;
  if(!pool || pool->signature!=I386_POOL_SIGNATURE || pool->size&511 ||
      pool->alloced_u8s!=pool->size || !(0<=pool->used_u8s<=pool->size)) return FALSE;
  for(region=pool->regions;region;region=region->next) {
    if(count++>=pool->region_count || region->pool!=pool || region->last!=last ||
        region->type!=MRT_RAM || region->flags || !region->base || region->size<512 ||
        region->size>0xFFFFFFFF || region->size&511 || region->used&511 ||
        region->used>region->size) return FALSE;
    base=(region->base+0)(U64);
    if(base&511 || base+region->size>0x100000000) return FALSE;
    total+=region->size; used+=region->used; last=region;
  }
  return count==pool->region_count && total==pool->size && used==pool->used_u8s;
}
CI386PoolRegion *I386MemBlockRegion(CI386PublicPool *pool,CMemBlk *block)
{//Pool shape already validated; test address membership before reading the block.
  CI386PoolRegion *region;
  U64 address=(block+0)(U64),base;
  if(!block || address&511) return 0;
  for(region=pool->regions;region;region=region->next) {
    base=(region->base+0)(U64);
    if(base<=address && address<=base+region->size-512) return region;
  }
  return 0;
}
Bool I386MemBlockValid(CI386PublicPool *pool,CMemBlk *block,U32 signature)
{
  CI386PoolRegion *region=I386MemBlockRegion(pool,block);
  return region && block->mb_signature==signature && block->pags &&
    (block+0)(U64)+(block->pags+0)(U64)*512<=(region->base+0)(U64)+region->size;
}
Bool I386MemRangesOverlap(U64 a,U64 size_a,U64 b,U64 size_b)
{
  return a<b+size_b && b<a+size_a;
}
Bool I386MemPoolEmpty(CI386PublicPool *pool)
{//Fresh control or an empty pool; legacy single-inline-region reinit is allowed.
  U32 flags=I386IrqSave;
  I64 i;
  if(!pool || (pool+0)(U64)+sizeof(CI386PublicPool)>0x100000000 ||
      pool->signature==I386_POOL_SIGNATURE && (pool->locked_flags || pool->growing || pool->grow || pool->used_u8s ||
       pool->region_count>1 || pool->regions && pool->regions!=&pool->initial)) {
    I386IrqRestore(flags); return FALSE;
  }
  for(i=0;i<sizeof(CI386PublicPool);i++) pool(U8 *)[i]=0;
  pool->signature=I386_POOL_SIGNATURE;
  I386IrqRestore(flags); return TRUE;
}
Bool I386MemPoolAdd(CI386PublicPool *pool,CI386PoolRegion *region,U8 *arena,I64 size)
{
  U32 flags=I386IrqSave;
  U64 base=(arena+0)(U64),control=(region+0)(U64),pool_address=(pool+0)(U64);
  CI386PoolRegion *other;
  CMemBlk *block=arena;
  Bool result=FALSE;
  if(!I386MemPoolValid(pool) || pool->locked_flags || !region || !arena || base&511 ||
      size<512 || size>0xFFFFFFFF || size&511 || base+size>0x100000000 ||
      (pool->size+0)(U64)+size>0xFFFFFFFF || pool->region_count==0xFFFFFFFF ||
      control+sizeof(CI386PoolRegion)>0x100000000 ||
      I386MemRangesOverlap(base,size,pool_address,sizeof(CI386PublicPool)) ||
      I386MemRangesOverlap(base,size,control,sizeof(CI386PoolRegion)) ||
      region!=&pool->initial && I386MemRangesOverlap(control,sizeof(CI386PoolRegion),
        pool_address,sizeof(CI386PublicPool))) goto done;
  for(other=pool->regions;other;other=other->next)
    if(I386MemRangesOverlap(base,size,(other->base+0)(U64),other->size) ||
        I386MemRangesOverlap(base,size,(other+0)(U64),sizeof(CI386PoolRegion)) ||
        I386MemRangesOverlap(control,sizeof(CI386PoolRegion),(other->base+0)(U64),other->size) ||
        I386MemRangesOverlap(control,sizeof(CI386PoolRegion),(other+0)(U64),sizeof(CI386PoolRegion))) goto done;
  if(region->pool) goto done;
  pool->locked_flags=1;
  region->base=arena; region->size=size; region->type=MRT_RAM; region->flags=0;
  region->pool=pool; region->used=0; region->last=0; region->next=pool->regions;
  if(pool->regions) pool->regions->last=region;
  pool->regions=region; pool->region_count++; pool->size+=size; pool->alloced_u8s+=size;
  block->mb_signature=MBS_UNUSED_SIGNATURE_VAL; block->pags=size>>MEM_PAG_BITS;
  block->last=0; block->next=pool->mem_free_lst; pool->mem_free_lst=block;
  pool->locked_flags=0; result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
Bool I386MemPoolInit(CI386PublicPool *pool,U8 *arena,I64 size)
{//Validate before touching either control or arena, including failed reinit.
  U64 base=(arena+0)(U64),control=(pool+0)(U64);
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(pool && arena && !(base&511) && 512<=size<=0xFFFFFFFF && !(size&511) &&
      base+size<=0x100000000 && control+sizeof(CI386PublicPool)<=0x100000000 &&
      !I386MemRangesOverlap(control,sizeof(CI386PublicPool),base,size) && I386MemPoolEmpty(pool))
    result=I386MemPoolAdd(pool,&pool->initial,arena,size);
  I386IrqRestore(flags); return result;
}
CMemBlk **I386MemPoolFreeHead(CI386PublicPool *pool,I64 index)
{
  if(!index) return &pool->mem_free_lst;
  index--;
  if(index<MEM_FREE_PAG_HASH_SIZE) return &pool->free_pag_hash[index];
  return &pool->free_pag_hash2[index-MEM_FREE_PAG_HASH_SIZE];
}
Bool I386MemPoolRemove(CI386PublicPool *pool,CI386PoolRegion *region)
{//Return only a wholly unused region. Caller releases its record/backing storage.
  U32 flags=I386IrqSave;
  CI386PoolRegion *other;
  CMemBlk *block,**link;
  I64 i,total=0,remaining;
  Bool found=FALSE,result=FALSE;
  if(!I386MemPoolValid(pool) || pool->locked_flags || !region) goto done;
  for(other=pool->regions;other;other=other->next) if(other==region) found=TRUE;
  if(!found || region->used) goto done;
  //Preflight every list before mutation; no dangling free-list pointer may remain.
  remaining=pool->size/512;
  for(i=0;i<1+MEM_FREE_PAG_HASH_SIZE+64-MEM_PAG_BITS;i++)
    for(block=*I386MemPoolFreeHead(pool,i);block;block=block->next) {
      if(!remaining-- || !I386MemBlockValid(pool,block,MBS_UNUSED_SIGNATURE_VAL)) goto done;
      if(I386MemBlockRegion(pool,block)==region) total+=(block->pags+0)(U64)*512;
    }
  if(total!=region->size) goto done;
  pool->locked_flags=1;
  for(i=0;i<1+MEM_FREE_PAG_HASH_SIZE+64-MEM_PAG_BITS;i++) {
    link=I386MemPoolFreeHead(pool,i);
    while(block=*link) {
      if(I386MemBlockRegion(pool,block)==region) *link=block->next;
      else link=&block->next;
    }
  }
  if(region->last) region->last->next=region->next;
  else pool->regions=region->next;
  if(region->next) region->next->last=region->last;
  pool->size-=region->size; pool->alloced_u8s-=region->size; pool->region_count--;
  region->next=0; region->last=0; region->pool=0; region->used=0;
  pool->locked_flags=0; result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
CMemBlk *I386MemPageAlloc(CI386PublicPool *pool,I64 pages)
{
  U32 flags=I386IrqSave;
  CMemBlk *block=0,**link;
  CI386PoolRegion *region;
  I64 i=0,n,remaining;
  Bool retried=FALSE,grown;
  if(!I386MemPoolValid(pool) || pool->locked_flags || pages<1 || pages>0xFFFFFFFF/512) goto done;
  if(pages<MEM_FREE_PAG_HASH_SIZE) link=&pool->free_pag_hash[pages];
  else {
    n=pages-MEM_EXTRA_HASH2_PAGS;
    while(n) { i++; n>>=1; }
    pages=(1<<i)+MEM_EXTRA_HASH2_PAGS;
    link=&pool->free_pag_hash2[i];
  }
retry:
  if(!I386MemPoolValid(pool) || pool->locked_flags) goto done;
  pool->locked_flags=1;
  if(block=*link) {
    if(!I386MemBlockValid(pool,block,MBS_UNUSED_SIGNATURE_VAL) || block->pags!=pages) goto invalid;
    *link=block->next; goto found;
  }
  link=&pool->mem_free_lst; remaining=pool->size/512;
  while(block=*link) {
    if(!remaining-- || !I386MemBlockValid(pool,block,MBS_UNUSED_SIGNATURE_VAL)) goto invalid;
    if(block->pags>=pages) {
      if(block->pags==pages) *link=block->next;
      else {
        block->pags-=pages;
        block=block(U8 *)+(block->pags+0)(U64)*512;
        block->pags=pages;
      }
      goto found;
    }
    link=&block->next;
  }
  //A larger returned page block can satisfy a smaller request in its entirety.
  for(i=0;i<64-MEM_PAG_BITS;i++)
    if(block=pool->free_pag_hash2[i]) {
      if(!I386MemBlockValid(pool,block,MBS_UNUSED_SIGNATURE_VAL)) goto invalid;
      if(block->pags>=pages) { pool->free_pag_hash2[i]=block->next; goto found; }
    }
  pool->locked_flags=0;
  if(!retried && pool->grow && !pool->growing) {
    retried=TRUE; pool->growing=1;
    grown=(*pool->grow)(pool,pages);
    pool->growing=0;
    if(grown) {
      if(pages<MEM_FREE_PAG_HASH_SIZE) link=&pool->free_pag_hash[pages];
      else {
        n=pages-MEM_EXTRA_HASH2_PAGS; i=0;
        while(n>>=1) i++;
        link=&pool->free_pag_hash2[i];
      }
      goto retry;
    }
  }
invalid:
  block=0; pool->locked_flags=0; goto done;
found:
  region=I386MemBlockRegion(pool,block);
  region->used+=(block->pags+0)(U64)*512;
  block->mb_signature=MBS_USED_SIGNATURE_VAL; block->next=block->last=0;
  pool->used_u8s+=(block->pags+0)(U64)*512; pool->locked_flags=0;
done:
  I386IrqRestore(flags); return block;
}
Bool I386MemPageFree(CI386PublicPool *pool,CMemBlk *block)
{
  U32 flags=I386IrqSave;
  I64 i=0,n;
  CMemBlk **link;
  CI386PoolRegion *region;
  Bool result=FALSE;
  if(!I386MemPoolValid(pool) || pool->locked_flags ||
      !I386MemBlockValid(pool,block,MBS_USED_SIGNATURE_VAL) ||
      pool->used_u8s<(block->pags+0)(U64)*512) goto done;
  region=I386MemBlockRegion(pool,block);
  if(region->used<(block->pags+0)(U64)*512) goto done;
  if(block->pags<MEM_FREE_PAG_HASH_SIZE) link=&pool->free_pag_hash[block->pags];
  else {
    n=block->pags-MEM_EXTRA_HASH2_PAGS;
    if(n&(n-1)) goto done;
    while(n>>=1) i++;
    link=&pool->free_pag_hash2[i];
  }
  pool->locked_flags=1;
  region->used-=(block->pags+0)(U64)*512;
  pool->used_u8s-=(block->pags+0)(U64)*512;
  block->mb_signature=MBS_UNUSED_SIGNATURE_VAL; block->last=0;
  block->next=*link; *link=block;
  pool->locked_flags=0; result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
Bool I386MemHeapInit(CHeapCtrl *hc,CI386PublicPool *pool,CTask *task=0)
{
  I64 i;
  U32 flags=I386IrqSave;
  if(!hc || !I386MemPoolValid(pool) || pool->locked_flags ||
      hc->hc_signature==HEAP_CTRL_SIGNATURE_VAL && hc->alloced_u8s) {
    I386IrqRestore(flags); return FALSE;
  }
  for(i=0;i<sizeof(CHeapCtrl);i++) hc(U8 *)[i]=0;
  hc->bp=pool; hc->hc_signature=HEAP_CTRL_SIGNATURE_VAL; hc->mem_task=task;
  hc->next_mem_blk=hc->last_mem_blk=&hc->next_mem_blk;
  hc->next_um=hc->last_um=(&hc->next_um)(U8 *)-offset(CMemUsed.next);
  I386IrqRestore(flags); return TRUE;
}
CMemBlk *I386MemHeapPages(CHeapCtrl *hc,I64 pages)
{
  CMemBlk *block=I386MemPageAlloc(hc->bp,pages);
  if(block) {
    block->last=hc->last_mem_blk; block->next=&hc->next_mem_blk;
    block->last->next=block; hc->last_mem_blk=block;
    hc->alloced_u8s+=(block->pags+0)(U64)*512;
  }
  return block;
}
//Keep the original record offsets. Place a native used header at 4 mod 8 so
//its 12-byte prefix ends on an eight-byte-aligned payload, including page blocks.
#define I386_MEM_BLOCK_OFFSET (((sizeof(CMemBlk)+offset(CMemUsed.start)+7)&~7)-offset(CMemUsed.start))
U8 *I386MemAlloc(CHeapCtrl *hc,I64 size)
{
  U32 flags=I386IrqSave;
  I64 span;
  CMemBlk *block;
  CMemUnused *unused,**link;
  CMemUsed *used=0;
  U8 *result=0;
  if(!hc || hc->hc_signature!=HEAP_CTRL_SIGNATURE_VAL || hc->locked_flags ||
      !I386MemPoolValid(hc->bp) || size<0 || size>0xFFFFFFFF-offset(CMemUsed.start)-7) goto done;
  span=(size+offset(CMemUsed.start)+7)&~7;
  hc->locked_flags=1;
  if(span<MEM_HEAP_HASH_SIZE) {
    link=&hc->heap_hash[span/sizeof(U8 *)];
    if(unused=*link) { *link=unused->next; used=unused; }
    else {
      link=&hc->malloc_free_lst;
      while(unused=*link) {
        if(unused->size==span) { *link=unused->next; used=unused; break; }
        if(unused->size>=span+sizeof(CMemUnused)) {
          unused->size-=span; used=unused(U8 *)+unused->size; break;
        }
        link=&unused->next;
      }
      if(!used) {
        block=I386MemHeapPages(hc,(span+16*MEM_PAG_SIZE-1)>>MEM_PAG_BITS);
        if(!block) goto unlock;
        hc->last_mergable=block;
        unused=block(U8 *)+I386_MEM_BLOCK_OFFSET;
        unused->size=((block->pags+0)(U64)*512-I386_MEM_BLOCK_OFFSET)&~7;
        unused->next=hc->malloc_free_lst; hc->malloc_free_lst=unused;
        unused->size-=span; used=unused(U8 *)+unused->size;
      }
    }
  } else {
    block=I386MemHeapPages(hc,(span+I386_MEM_BLOCK_OFFSET+MEM_PAG_SIZE-1)>>MEM_PAG_BITS);
    if(!block) goto unlock;
    used=block(U8 *)+I386_MEM_BLOCK_OFFSET;
    span=((block->pags+0)(U64)*512-I386_MEM_BLOCK_OFFSET)&~7;
  }
  used->hc=hc; used->size=span; hc->used_u8s+=span;
  result=&used->start;
unlock:
  hc->locked_flags=0;
done:
  I386IrqRestore(flags); return result;
}
I64 I386MemSize(U8 *ptr)
{
  CMemUsed *used;
  if(!ptr) return 0;
  used=ptr-offset(CMemUsed.start);
  if(!used->hc || used->hc->hc_signature!=HEAP_CTRL_SIGNATURE_VAL ||
      used->size<offset(CMemUsed.start) || used->size&7) return -1;
  return used->size-offset(CMemUsed.start);
}
Bool I386MemFree(U8 *ptr)
{
  U32 flags=I386IrqSave;
  CMemUsed *used;
  CMemUnused *unused;
  CHeapCtrl *hc;
  CMemBlk *block,*next,*last;
  I64 span;
  Bool result=FALSE;
  if(!ptr) { result=TRUE; goto done; }
  if(I386MemSize(ptr)<0) goto done;
  used=ptr-offset(CMemUsed.start); hc=used->hc; span=used->size;
  if(hc->locked_flags || hc->used_u8s<span || !I386MemPoolValid(hc->bp)) goto done;
  hc->locked_flags=1;
  if(span<MEM_HEAP_HASH_SIZE) {
    unused=used; unused->next=hc->heap_hash[span/sizeof(U8 *)];
    hc->heap_hash[span/sizeof(U8 *)]=unused;
  } else {
    block=used(U8 *)-I386_MEM_BLOCK_OFFSET;
    next=block->next; last=block->last;
    if(!I386MemPageFree(hc->bp,block)) { hc->locked_flags=0; goto done; }
    next->last=last; last->next=next;
    hc->alloced_u8s-=(block->pags+0)(U64)*512;
  }
  hc->used_u8s-=span; hc->locked_flags=0; result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
Bool I386MemHeapDestroy(CHeapCtrl *hc)
{
  U32 flags=I386IrqSave;
  CMemBlk *block,*next;
  if(!hc || hc->hc_signature!=HEAP_CTRL_SIGNATURE_VAL || hc->locked_flags ||
      !I386MemPoolValid(hc->bp) || hc->bp->locked_flags) {
    I386IrqRestore(flags); return FALSE;
  }
  hc->locked_flags=1;
  block=hc->next_mem_blk;
  while(block!=&hc->next_mem_blk) {
    next=block->next;
    if(!I386MemPageFree(hc->bp,block)) {
      hc->locked_flags=0; I386IrqRestore(flags); return FALSE;
    }
    hc->alloced_u8s-=(block->pags+0)(U64)*512;
    hc->next_mem_blk=next; next->last=&hc->next_mem_blk;
    block=next;
  }
  hc->used_u8s=0; hc->last_mergable=0; hc->malloc_free_lst=0;
  hc->hc_signature=0; hc->locked_flags=0;
  I386IrqRestore(flags); return TRUE;
}
