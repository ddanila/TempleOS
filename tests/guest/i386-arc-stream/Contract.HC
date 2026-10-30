Bool ArcStreamSame(U8 *a,U8 *b,I64 n)
{ I64 i;for(i=0;i<n;i++)if(a[i]!=b[i])return FALSE;return TRUE; }
I64 ArcStreamContract()
{
  I64 mode,i,bytes,mask=0;Bool ok;U8 *src,*packed,*decoded,*whole;
  CArcCtrl *c,*d;CArcCompress *archive;
  for(mode=CT_7_BIT;mode<=CT_8_BIT;mode++) {
    src=MAlloc(512);packed=CAlloc(2048);decoded=CAlloc(513);
    for(i=0;i<512;i++) {
      if(mode==CT_8_BIT)src[i]=(i%13)+128;
      else src[i]=(i%13)+65;
    }
    c=ArcCtrlNew(FALSE,mode);c->src_buf=src;c->src_size=256;
    c->dst_buf=packed;c->dst_size=2048*8;c->dst_pos=sizeof(CArcCompress)*8;
    ArcCompressBuf(c);ok=c->src_pos==256;
    c->src_size=512;ArcCompressBuf(c);
    ok=ok && c->src_pos==512 && ArcFinishCompression(c);
    bytes=(c->dst_pos+7)>>3;archive=packed;
    archive->compressed_size=bytes;archive->expanded_size=512;archive->compression_type=mode;
    whole=ExpandBuf(archive);ok=ok && ArcStreamSame(whole,src,512) && !whole[512];
    d=ArcCtrlNew(TRUE,mode);d->src_buf=packed;d->src_pos=sizeof(CArcCompress)*8;
    d->src_size=bytes*8;d->dst_buf=decoded;d->dst_size=256;
    ArcExpandBuf(d);ok=ok && d->dst_pos==256 && ArcStreamSame(decoded,src,256);
    d->dst_size=512;ArcExpandBuf(d);
    ok=ok && d->dst_pos==512 && ArcStreamSame(decoded,src,512);
    if(ok)mask|=1<<(mode-CT_7_BIT);
    ArcCtrlDel(c);ArcCtrlDel(d);Free(whole);Free(decoded);Free(packed);Free(src);
  }
  return mask;
}
