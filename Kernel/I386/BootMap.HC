#include "/Kernel/I386/BootMap.HH"
public Bool I386BootMapArena(CI386BootInfo *info,CI386BootMap *map,
  CI386MemRange *reserved,I64 count,CI386MemRange *result)
{//Stable caller-owned map; publish only after validating every range.
  CI386MemRange low;
  CI386BootMapEntry *entry;
  U64 lo,hi,cursor,end,next,covered,begin,gap_end,best_base=0,best_size=0;
  I64 i,j,block_count;
  if(!result || !I386BootArena(info,0,0,&low) || !map ||
      map->magic!=I386_BOOT_MAP_MAGIC || map->version!=1 ||
      map->complete!=1 || map->count<1 || map->count>I386_BOOT_MAP_MAX ||
      count<0 || count>128 || count && !reserved) return FALSE;
  for(i=0;i<count;i++) {
    lo=reserved[i].base; hi=lo+reserved[i].size;
    if(!reserved[i].size || hi>0x100000000) return FALSE;
  }
  for(i=0;i<map->count;i++) {
    entry=&map->entries[i];
    if(!entry->size || entry->base+entry->size<entry->base) return FALSE;
  }
  block_count=count+map->count;
  for(i=0;i<map->count;i++) {
    entry=&map->entries[i];
    //Only plain volatile usable RAM. Unknown attributes/types stay excluded.
    if(entry->type!=1 || entry->attributes!=1) goto next_entry;
    cursor=entry->base; end=cursor+entry->size;
    if(cursor<0x110000) cursor=0x110000;
    if(end>0x100000000) end=0x100000000;
    while(cursor<end) {
      next=end; covered=cursor;
      //Subtract caller reservations, the legacy device hole, and every
      //non-usable firmware range. Reserved coverage wins over usable overlaps.
      for(j=-1;j<block_count;j++) {
        if(j<0) { lo=0xF00000; hi=0x1000000; }
        else if(j<count) { lo=reserved[j].base; hi=lo+reserved[j].size; }
        else {
          entry=&map->entries[j-count];
          if(entry->type==1 && entry->attributes==1) goto next_block;
          lo=entry->base; hi=lo+entry->size;
        }
        if(lo<=cursor && hi>covered) {
          covered=hi; if(covered>end) covered=end;
        } else if(lo>cursor && lo<next) next=lo;
next_block:;
      }
      if(covered>cursor) cursor=covered;
      else {
        begin=(cursor+7)&~7; gap_end=next&~7;
        if(gap_end>begin && (gap_end-begin>best_size ||
            gap_end-begin==best_size && begin<best_base)) {
          best_base=begin; best_size=gap_end-begin;
        }
        cursor=next;
      }
    }
next_entry:;
  }
  if(best_size<24) return FALSE;
  result->base=best_base; result->size=best_size; return TRUE;
}
