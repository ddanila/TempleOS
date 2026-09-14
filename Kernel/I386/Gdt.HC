public Bool I386GdtInit(U8 *table,U8 *task,I64 task_size,U8 *cpu,I64 cpu_size)
{//Caller owns forty writable bytes and live task/CPU records.
  I64 i;
  if(!table || (table+0)(U64)+40>0x100000000 || !task || !cpu ||
      task_size<1 || task_size>0x100000 || cpu_size<1 || cpu_size>0x100000 ||
      (task+0)(U64)+task_size>0x100000000 ||
      (cpu+0)(U64)+cpu_size>0x100000000) return 0;
  for(i=0;i<40;i++) table[i]=0;
  table(U64 *)[1]=0x00CF9A000000FFFF;
  table(U64 *)[2]=0x00CF92000000FFFF;
  I386DataSegment(table+24,task,task_size);
  I386DataSegment(table+32,cpu,cpu_size);
  return 1;
}
public Bool I386GdtLoad(U8 *table,I64 count)
{
  U8 descriptor[6];
  U64 base=(table+0)(U64);
  I64 limit;
  if(!table || count<3 || count>8192 || base+count*8>0x100000000 ||
      (GetRFlags&0x200)) return 0;
  limit=count*8-1;
  descriptor[0]=limit; descriptor[1]=limit>>8;
  descriptor[2]=base; descriptor[3]=base>>8;
  descriptor[4]=base>>16; descriptor[5]=base>>24;
  asm {
    LEA EAX,U32 &descriptor[EBP]
    LGDT U32 [EAX]
  }
  return 1;
}
public Bool I386GdtRead(U8 *descriptor)
{
  if(!descriptor || (descriptor+0)(U64)+6>0x100000000) return 0;
  asm {
    MOV EAX,U32 &descriptor[EBP]
    SGDT U32 [EAX]
  }
  return 1;
}
