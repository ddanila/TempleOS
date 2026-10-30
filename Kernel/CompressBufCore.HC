CArcCompress *CompressBuf(U8 *src,I64 size,CTask *mem_task=NULL)
{//See $LK,"::/Demo/Dsk/SerializeTree.HC"$.
  CArcCompress *arc;
  I64 size_out,compression_type=ArcDetermineCompressionType(src,size);
  CArcCtrl *c=ArcCtrlNew(FALSE,compression_type);
  c->src_size=size;
  c->src_buf=src;
  c->dst_size=(size+sizeof(CArcCompress))<<3;
  c->dst_buf=CAlloc(c->dst_size>>3);
  c->dst_pos=sizeof(CArcCompress)<<3;
  ArcCompressBuf(c);
  if (ArcFinishCompression(c) && c->src_pos==c->src_size) {
    size_out=(c->dst_pos+7)>>3;
    arc=MAlloc(size_out,mem_task);
    MemCpy(arc,c->dst_buf,size_out);
    arc->compression_type=compression_type;
    arc->compressed_size=size_out;
  } else {
    arc=MAlloc(size+sizeof(CArcCompress),mem_task);
    MemCpy(&arc->body,src,size);
    arc->compression_type=CT_NONE;
    arc->compressed_size=size+sizeof(CArcCompress);
  }
  arc->expanded_size=size;
  Free(c->dst_buf);
  ArcCtrlDel(c);
  return arc;
}
