//Original Kernel/StrA.HC string-copy semantics with native pointer/stack widths.
U0 MemoryStrCopy(U8 *dst,U8 *src)
{
  I64 step;
  U8 ch;
  if(!dst) return;
  if(!src) { *dst=0; return; }
  if(GetRFlags&0x400) step=-1;
  else step=1;
  do {
    ch=*src; *dst=ch;
    src+=step; dst+=step;
  } while(ch);
}
