Bool I386IdtRange(U8 *table,I64 count)
{
  U64 base=(table+0)(U64);
  return table && count>=1 && count<=256 && base+count*8<=0x100000000;
}
U0 I386IdtGate(U8 *gate,U8 *handler,U16 selector)
{
  U64 address=(handler+0)(U64);
  gate[0]=address; gate[1]=address>>8;
  gate[2]=selector; gate[3]=selector>>8;
  gate[4]=0; gate[5]=0x8E;
  gate[6]=address>>16; gate[7]=address>>24;
}
public Bool I386IdtInit(U8 *table,I64 count,U8 *fallback,U16 selector)
{//Build inactive gates; caller must mask interrupts before editing a live IDT.
  I64 i;
  if(!I386IdtRange(table,count) || !fallback || !selector || (selector&7)) return 0;
  for(i=0;i<count;i++) I386IdtGate(table+i*8,fallback,selector);
  return 1;
}
public Bool I386IdtSet(U8 *table,I64 count,I64 vector,U8 *handler,U16 selector)
{
  if(!I386IdtRange(table,count) || vector<0 || vector>=count ||
      !handler || !selector || (selector&7)) return 0;
  I386IdtGate(table+vector*8,handler,selector);
  return 1;
}
public Bool I386IdtLoad(U8 *table,I64 count)
{//The selector and all handler lifetimes must have been validated by the caller.
  U8 descriptor[6];
  U64 base=(table+0)(U64);
  I64 limit;
  if(!I386IdtRange(table,count) || (GetRFlags&0x200)) return 0;
  limit=count*8-1;
  descriptor[0]=limit; descriptor[1]=limit>>8;
  descriptor[2]=base; descriptor[3]=base>>8;
  descriptor[4]=base>>16; descriptor[5]=base>>24;
  asm {
    LEA EAX,U32 &descriptor[EBP]
    LIDT U32 [EAX]
  }
  return 1;
}
public Bool I386IdtRead(U8 *descriptor)
{
  if(!descriptor || (descriptor+0)(U64)+6>0x100000000) return 0;
  asm {
    MOV EAX,U32 &descriptor[EBP]
    SIDT U32 [EAX]
  }
  return 1;
}
