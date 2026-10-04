#include "/Kernel/I386/Arc.HH"
U0 I386ArcPutCode(CArcCtrl *c,I64 value)
{
  I64 bit;
  for(bit=0;bit<c->cur_bits_in_use;bit++)
    if(value&(1<<bit)) c->dst_buf[(c->dst_pos+bit)>>3]|=1<<((c->dst_pos+bit)&7);
}
U0 I386ArcCompressBuf(CArcCtrl *c)
{//Use $LK,"CompressBuf",A="MN:CompressBuf"$() unless doing more than one buf.
  CArcEntry *tmp;
  I64 ch,basecode;
  U8 *src_ptr,*src_limit;

  src_ptr=c->src_buf+c->src_pos;
  src_limit=c->src_buf+c->src_size;

  if (c->saved_basecode==U32_MAX)
    basecode=*src_ptr++;
  else
    basecode=c->saved_basecode;

  while (src_ptr<src_limit && c->dst_pos+c->cur_bits_in_use<=c->dst_size) {
    I386ArcEntryGet(c);
ac_start:
    if (src_ptr>=src_limit) goto ac_done;
    ch=*src_ptr++;
    if (tmp=c->hash[basecode])
      do {
	if (tmp->ch==ch) {
	  basecode=tmp-&c->compress[0];
	  goto ac_start;
	}
      } while (tmp=tmp->next);

    I386ArcPutCode(c,basecode);
    c->dst_pos+=c->cur_bits_in_use;

    c->entry_used=TRUE;
    tmp=c->cur_entry;
    tmp->basecode=basecode;
    tmp->ch=ch;
    tmp->next=c->hash[basecode];
    c->hash[basecode]=tmp;

    basecode=ch;
  }
ac_done:
  c->saved_basecode=basecode;
  c->src_pos=src_ptr-c->src_buf;
}

Bool I386ArcFinishCompression(CArcCtrl *c)
{//Do closing touch on archivew ctrl struct.
  if (c->dst_pos+c->cur_bits_in_use<=c->dst_size) {
    I386ArcPutCode(c,c->saved_basecode);
    c->dst_pos+=c->next_bits_in_use;
    return TRUE;
  } else
    return FALSE;
}

CArcCompress *I386CompressBuf(CI386Heap *heap,U8 *src,I64 size)
{
  CArcCtrl *c=0;
  CArcCompress *arc;
  I64 i,kind=CT_7_BIT,bytes=size+sizeof(CArcCompress);
  if(size<0 || size>0x7FFFFFFF || size && !src) return 0;
  arc=I386HeapAlloc(heap,bytes,TRUE);
  if(!arc) return 0;
  for(i=0;i<size;i++) if(src[i]&0x80) {kind=CT_8_BIT;break;}
  if(size) c=I386ArcCtrlNew(heap,FALSE,kind);
  if(size && !c) {I386HeapFree(heap,arc);return 0;}
  if(c) {
    c->src_size=size; c->src_buf=src;
    c->dst_size=bytes*8; c->dst_buf=arc;
    c->dst_pos=sizeof(CArcCompress)*8;
    I386ArcCompressBuf(c);
    if(I386ArcFinishCompression(c) && c->src_pos==size) bytes=(c->dst_pos+7)>>3;
    else kind=CT_NONE;
    I386ArcCtrlDel(heap,c);
  } else kind=CT_NONE;
  if(kind==CT_NONE) {
    bytes=size+sizeof(CArcCompress);
    for(i=0;i<size;i++) (&arc->body)(U8 *)[i]=src[i];
  }
  arc->compression_type=kind; arc->compressed_size=bytes; arc->expanded_size=size;
  return arc;
}
