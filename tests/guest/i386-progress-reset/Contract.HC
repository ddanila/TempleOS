I64 ProgressResetContract()
{
  CProgress saved[4];I64 i,mask=0;U8 *p=sys_progresses;
  MemCpy(saved,sys_progresses,sizeof(saved));
  MemSet(sys_progresses,0x7A,sizeof(saved));
  ProgressBarsRst;
  for(i=0;i<sizeof(saved);i++)if(p[i])goto done;
  mask=1;
done:
  MemCpy(sys_progresses,saved,sizeof(saved));return mask;
}
