Bool ArcVectors(U8 *vectors)
{
  I64 mode,pattern,size,i,used=8,packed,limit;
  U32 random;
  U8 *source,*output,*check;
  CArcCtrl *c,*d;
  CArcCompress *arc;
  *vectors(I64 *)=6;
  for(mode=CT_7_BIT;mode<=CT_8_BIT;mode++) for(pattern=0;pattern<3;pattern++) {
    size=32768; if(pattern==2) size=1;
    source=MAlloc(size); random=0x12345678;
    for(i=0;i<size;i++) {
      random=random*1664525+1013904223;
      if(pattern==0) source[i]='Q';
      else source[i]=random>>24;
      if(mode==CT_7_BIT) source[i]&=127;
    }
    output=CAlloc(size*2+64);
    c=ArcCtrlNew(FALSE,mode); c->src_buf=source; c->src_size=size;
    c->dst_buf=output; c->dst_size=(size*2+64)<<3; c->dst_pos=17<<3;
    ArcCompressBuf(c);
    if(!ArcFinishCompression(c) || c->src_pos!=size) return FALSE;
    packed=(c->dst_pos+7)>>3; arc=output;
    arc->compressed_size=packed; arc->expanded_size=size; arc->compression_type=mode;
    check=ExpandBuf(arc);
    if(MemCmp(check,source,size) || check[size]) return FALSE;
    Free(check);
    check=CAlloc(size+1); d=ArcCtrlNew(TRUE,mode);
    d->src_buf=output; d->src_pos=17<<3; d->src_size=packed<<3; d->dst_buf=check;
    limit=0;
    while(limit<size) {
      limit+=1+(limit%257); if(limit>size) limit=size;
      d->dst_size=limit; ArcExpandBuf(d);
      if(d->dst_pos!=limit || MemCmp(check,source,limit)) return FALSE;
    }
    if(used+16+packed>131072) return FALSE;
    (vectors+used)(I64 *)[0]=pattern; (vectors+used)(I64 *)[1]=packed;
    MemCpy(vectors+used+16,output,packed); used+=16+packed;
    ArcCtrlDel(c); ArcCtrlDel(d); Free(check); Free(source); Free(output);
  }
  return TRUE;
}
