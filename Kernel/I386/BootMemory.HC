#include "/Kernel/I386/BootMemory.HH"
public Bool I386BootArena(CI386BootInfo *info,CI386MemRange *reserved,
  I64 count,CI386MemRange *result,Bool extended=FALSE)
{//Largest permitted memory gap; ties choose lower addresses.
//Low memory through stage_end is reserved, including firmware data and the boot stack.
//The caller reserves all additional live buffers, stacks and hardware regions.
//Extended selection requires caller-verified A20 and a contiguous AH=88h RAM profile.
  I64 i,region,limit,low_limit,cursor,next,covered,begin,end,best_base=0,best_size=0;
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
  low_limit=limit;
  for (region=0;region<2;region++) {
    if (!region) { cursor=info->stage_end; limit=low_limit; }
    else {
      if (!extended || !(info->flags&2)) break;
      //Reserve A20 scratch and stay below the legacy 15-16 MiB device hole.
      cursor=0x110000; limit=0x100000+info->extended_kib*1024;
      if (limit>0xF00000) limit=0xF00000;
    }
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
  }
  if (best_size<24) return FALSE;
  result->base=best_base; result->size=best_size;
  return TRUE;
}
