// Independent source-level oracle for the complete pool-shape contract.
Bool PoolValidationReference(CI386PublicPool *pool)
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
CI386PublicPool validation_pool;
CI386PoolRegion validation_regions[3];
Bool PoolValidationParity(Bool expected)
{
  U64 pool_hash=Hash(&validation_pool,sizeof(validation_pool));
  U64 region_hash=Hash(&validation_regions,sizeof(validation_regions));
  Bool reference=PoolValidationReference(&validation_pool);
  Bool actual=I386MemPoolValid(&validation_pool);
  return reference==expected && actual==reference &&
    pool_hash==Hash(&validation_pool,sizeof(validation_pool)) &&
    region_hash==Hash(&validation_regions,sizeof(validation_regions));
}
I64 PoolValidationTest()
{
  CI386PublicPool *p=&validation_pool;
  CI386PoolRegion *r=&validation_regions[0];
  I64 i;
  if(I386MemPoolValid(0) || PoolValidationReference(0)) return 401;
  for(i=0;i<sizeof(validation_pool);i++) p(U8 *)[i]=0;
  for(i=0;i<sizeof(validation_regions);i++) r(U8 *)[i]=0;
  p->signature=I386_POOL_SIGNATURE;
  if(!PoolValidationParity(TRUE)) return 402;
  p->regions=r; p->region_count=3; p->size=3072; p->alloced_u8s=3072; p->used_u8s=1536;
  for(i=0;i<3;i++) {
    r[i].pool=p; r[i].base=0x10000+i*0x10000; r[i].size=(i+1)*512;
    r[i].used=i*512; r[i].type=MRT_RAM;
    if(i) r[i].last=&r[i-1];
    if(i<2) r[i].next=&r[i+1];
  }
  if(!PoolValidationParity(TRUE)) return 403;
  p->signature=0; if(!PoolValidationParity(FALSE)) return 404; p->signature=I386_POOL_SIGNATURE;
  p->size++; if(!PoolValidationParity(FALSE)) return 405; p->size--;
  p->alloced_u8s+=0x100000000; if(!PoolValidationParity(FALSE)) return 406; p->alloced_u8s-=0x100000000;
  p->used_u8s=-1; if(!PoolValidationParity(FALSE)) return 407; p->used_u8s=1536;
  p->used_u8s=0x100000000; if(!PoolValidationParity(FALSE)) return 408; p->used_u8s=1536;
  p->region_count=2; if(!PoolValidationParity(FALSE)) return 409; p->region_count=4;
  if(!PoolValidationParity(FALSE)) return 410; p->region_count=3;
  r[1].last=0; if(!PoolValidationParity(FALSE)) return 411; r[1].last=r;
  r[1].pool=0; if(!PoolValidationParity(FALSE)) return 412; r[1].pool=p;
  r[1].type=MRT_DEV; if(!PoolValidationParity(FALSE)) return 413; r[1].type=MRT_RAM;
  r[1].flags=1; if(!PoolValidationParity(FALSE)) return 414; r[1].flags=0;
  r[1].base=0; if(!PoolValidationParity(FALSE)) return 415; r[1].base=0x20001;
  if(!PoolValidationParity(FALSE)) return 416; r[1].base=0x20000;
  r[1].size=0; if(!PoolValidationParity(FALSE)) return 417; r[1].size=1025;
  if(!PoolValidationParity(FALSE)) return 418; r[1].size=0x100000000;
  if(!PoolValidationParity(FALSE)) return 419; r[1].size=1024;
  r[1].used=1; if(!PoolValidationParity(FALSE)) return 420; r[1].used=1536;
  if(!PoolValidationParity(FALSE)) return 421; r[1].used=512;
  r[2].next=r; if(!PoolValidationParity(FALSE)) return 422; r[2].next=0;
  // Each span fits and the first ends exactly at 4 GiB, but the sum of
  // spans exceeds the U32 pool size; do not accept a wrapped total.
  r[0].base=0x200; r[0].size=0xFFFFFE00;
  if(!PoolValidationParity(FALSE)) return 426;
  r[0].base=0x10000; r[0].size=512;
  r[1].base=0xFFFFFE00; if(!PoolValidationParity(FALSE)) return 423;
  r[1].size=512; p->size=2560; p->alloced_u8s=2560;
  if(!PoolValidationParity(TRUE)) return 424;
  r[1].base=0xFFFFFC00; r[1].size=0xFFFFFE00; r[1].used=0;
  p->size=0xFFFFFE00; p->alloced_u8s=0xFFFFFE00; p->used_u8s=1024;
  if(!PoolValidationParity(FALSE)) return 425;
  return 0;
}
