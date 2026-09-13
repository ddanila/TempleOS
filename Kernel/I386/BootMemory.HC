#include "/Kernel/I386/BootMemory.HH"
public Bool I386BootArena(CI386BootInfo *info,CI386MemRange *reserved,
  I64 count,CI386MemRange *result)
{//Largest conventional-memory gap after the loaded stage; ties choose lower addresses.
//Low memory through stage_end is reserved, including firmware data and the boot stack.
//The caller reserves all additional live buffers, stacks and hardware regions.
//Extended memory is recorded but never exposed here before A20/platform work.
  I64 i,limit,cursor,next,covered,begin,end,best_base=0,best_size=0;
  U64 lo,hi;
  if (!info || !result || count<0 || count>128 || (!reserved && count)) return FALSE;
  if (info->magic!=I386_BOOT_INFO_MAGIC || info->version!=1 ||
      !(info->flags&1) || info->flags&~3 || !info->conventional_kib ||
      info->conventional_kib>640 || info->extended_kib>65535 ||
      (!(info->flags&2) && info->extended_kib) ||
      info->stage_begin!=0x10000 || info->stage_end<0x10200 ||
      info->stage_end&511 || info->stage_end>0xA0000) return FALSE;
  limit=info->conventional_kib*1024;
  if (info->ebda_base) {
    if (info->ebda_base&15 || info->ebda_base>0xA0000) return FALSE;
    if (info->ebda_base<limit) limit=info->ebda_base;
  }
  for (i=0;i<count;i++) {
    lo=reserved[i].base; hi=lo+reserved[i].size;
    if (!reserved[i].size || hi>0x100000000) return FALSE;
  }
  cursor=info->stage_end;
  while (cursor<limit) {
    next=limit; covered=cursor;
    for (i=0;i<count;i++) {
      lo=reserved[i].base; hi=lo+reserved[i].size;
      if (lo<=cursor && hi>covered) {
        covered=hi;
        if (covered>limit) covered=limit;
      } else if (lo>cursor && lo<next) next=lo;
    }
    if (covered>cursor) cursor=covered;
    else {
      begin=(cursor+7)&~7; end=next&~7;
      if (end>begin && end-begin>best_size) {
        best_base=begin; best_size=end-begin;
      }
      cursor=next;
    }
  }
  if (best_size<24) return FALSE;
  result->base=best_base; result->size=best_size;
  return TRUE;
}
