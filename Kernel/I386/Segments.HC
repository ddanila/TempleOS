public Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size)
{//Writable 32-bit ring-0 data segment, byte granularity, maximum 1 MiB.
//Caller owns a live GDT slot, masks IRQs, and reloads affected selectors afterward.
  U64 address=(base+0)(U64);
  I64 limit;
  if (!descriptor || size<1 || size>0x100000 || address+size>0x100000000) return FALSE;
  limit=size-1;
  descriptor[0]=limit; descriptor[1]=limit>>8;
  descriptor[2]=address; descriptor[3]=address>>8;
  descriptor[4]=address>>16; descriptor[5]=0x92;
  descriptor[6]=0x40|(limit>>16); descriptor[7]=address>>24;
  return TRUE;
}
