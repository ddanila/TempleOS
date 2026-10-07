U8 MousePlaneMaskCore(I64 row)
{//Solid eight-pixel-wide arrow in the native low-bit-left plane layout.
  switch(row) {
    case 0: return 0x01;
    case 1: return 0x03;
    case 2: return 0x07;
    case 3: return 0x0F;
    case 4: return 0x1F;
    case 5: return 0x3F;
    case 6: return 0x0F;
    case 7: return 0x1B;
    case 8: return 0x31;
    case 9: return 0x20;
  }
  return 0;
}
U0 MousePlaneSplitXor(U8 **planes,I64 x,I64 y)
{
  I64 i,j,k,n;
  U8 m;
  if(!planes) return;
  for(i=0;i<10;i++) {
    m=MousePlaneMaskCore(i); j=y+i;
    if(0<=j<480) {
      k=x;
      while(m) {
        if(m&1 && 0<=k<640) {
          n=j*80+(k>>3);
          planes[0][n]^=1<<(k&7);
          planes[1][n]^=1<<(k&7);
          planes[2][n]^=1<<(k&7);
          planes[3][n]^=1<<(k&7);
        }
        m>>=1; k++;
      }
    }
  }
}
