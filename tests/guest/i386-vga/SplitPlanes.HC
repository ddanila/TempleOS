U8 gp_arrow[10]={1,3,7,15,31,63,15,27,49,32};
I64 gp_xs[8]={-8,-1,0,7,632,639,640,10};
I64 gp_ys[8]={0,-1,0,7,470,479,480,-10};
I64 SplitPlaneContract(CI386Heap *heap)
{//Independent bit-by-bit oracle, all pixel values, plane guards and ownership.
  U8 *planes[4],*blocks[4],*pixels;
  U8 *saved,*vga=0xA0000;
  I64 test,x,y,row,column,expected;
  I64 p,i,k,round,color,value,before=heap->used,allocations=heap->allocations;
  pixels=I386HeapAlloc(heap,307200);
  if(!pixels) return 101;
  for(p=0;p<4;p++) {
    blocks[p]=I386HeapAlloc(heap,38416);
    if(!blocks[p]) return 102;
    for(i=0;i<38416;i++)blocks[p][i]=0xA5;
    planes[p]=blocks[p]+8;
  }
  for(round=0;round<4;round++) {
    for(i=0;i<307200;i++) pixels[i]=(i*(2*round+1)+(i>>8)*round)&255;
    GraphicsPlanarSplitCore(planes,pixels);
    for(p=0;p<4;p++) {
      for(i=0;i<38400;i++) {
        value=0;
        for(k=0;k<8;k++) {
          color=pixels[i*8+k];
          if(color&(1<<p))value|=1<<k;
        }
        if(planes[p][i]!=value)return 103;
      }
      for(i=0;i<8;i++)
        if(blocks[p][i]!=0xA5 || blocks[p][38408+i]!=0xA5)return 104;
    }
  }
  for(test=0;test<8;test++) {
    x=gp_xs[test]; y=gp_ys[test];
    MousePlaneSplitXor(planes,x,y);
    for(p=0;p<4;p++)for(i=0;i<38400;i++) {
      value=0; expected=0;
      for(k=0;k<8;k++) {
        if(pixels[i*8+k]&(1<<p))value|=1<<k;
        row=i/80-y; column=(i%80)*8+k-x;
        if(0<=row<10 && 0<=column<8 && (gp_arrow[row]&(1<<column)))expected|=1<<k;
      }
      if(planes[p][i]!=(value^expected))return 112;
    }
    MousePlaneSplitXor(planes,x,y);
    for(p=0;p<4;p++)for(i=0;i<38400;i++) {
      value=0;
      for(k=0;k<8;k++)if(pixels[i*8+k]&(1<<p))value|=1<<k;
      if(planes[p][i]!=value)return 113;
    }
  }
  //Exercise independent-plane upload and all-or-nothing range validation.
  if(!I386VgaSplitRows(planes,0,480) || !I386VgaSplitRows(planes,480,0) ||
      I386VgaSplitRows(0,0,1) || I386VgaSplitRows(0xFFFFFFFC,0,1) ||
      I386VgaSplitRows(planes,-1,1) || I386VgaSplitRows(planes,479,2))return 107;
  for(p=0;p<4;p++) {
    OutU8(0x3CE,4); OutU8(0x3CF,p);
    for(i=0;i<38400;i++) {
      value=0;
      for(k=0;k<8;k++)if(pixels[i*8+k]&(1<<p))value|=1<<(7-k);
      if(vga[i]!=value)return 110;
    }
  }
  OutU8(0x3CE,4); OutU8(0x3CF,0);
  //A poisoned valid first plane must not be uploaded when the fourth is invalid.
  planes[0][0]^=255;
  saved=planes[3]; planes[3]=0;
  if(I386VgaSplitRows(planes,0,480))return 108;
  planes[3]=0xFFFF8000;
  if(I386VgaSplitRows(planes,0,480))return 109;
  planes[3]=saved;
  value=0;
  for(k=0;k<8;k++)if(pixels[k]&1)value|=1<<(7-k);
  if(vga[0]!=value)return 111;
  planes[0][0]^=255;
  for(p=0;p<4;p++) if(!I386HeapFree(heap,blocks[p]))return 105;
  if(!I386HeapFree(heap,pixels) || heap->used!=before ||
      heap->allocations!=allocations || !I386HeapValid(heap))return 106;
  return 0;
}
