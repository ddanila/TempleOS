//Private whole-buffer decoder. Dictionary links are indices+1 (zero is null),
//preserving the original leaf-recycling order without pointer-sized records.
class CI386CompactArc
{
  U16 prefix[4096],next[4096],head[4096];
  U8 suffix[4096],valid[512],stack[4096];
  I64 minimum,free_idx,free_limit,bits,current,pending;
};
Bool I386CompactArcEntry(CI386CompactArc *c)
{
  I64 i=c->free_idx,count=0,entry,previous;
  c->current=c->pending;
  if(c->bits<ARC_BITS_MAX) {
    c->pending=i++;
    if(i==c->free_limit) { c->bits++;c->free_limit=1<<c->bits; }
  } else {
    do {
      if(++i==c->free_limit)i=c->minimum;
      if(++count>4096)return FALSE;
    } while(c->head[i]);
    c->pending=i;
    entry=c->head[c->prefix[i]];previous=0;
    while(entry) {
      if(entry==i+1) {
        if(previous)c->next[previous-1]=c->next[i];
        else c->head[c->prefix[i]]=c->next[i];
        break;
      }
      previous=entry;entry=c->next[entry-1];
      if(++count>8192)return FALSE;
    }
  }
  c->free_idx=i;
  return TRUE;
}
I64 I386CompactArcChain(CI386CompactArc *c,I64 code,I64 forbidden)
{
  I64 length=1;
  while(code>=c->minimum) {
    if(code>=4096 || code==forbidden || !(c->valid[code>>3]&(1<<(code&7))) || length>=4096)return -1;
    length++;code=c->prefix[code];
  }
  return length;
}
I64 I386CompactArcRead(U8 *source,I64 *position,I64 limit,I64 bits)
{
  I64 i,bit,code=0;
  if(bits>limit-*position)return -1;
  for(i=0;i<bits;i++) {
    bit=*position+i;
    if(source[bit>>3]&(1<<(bit&7)))code|=1<<i;
  }
  *position+=bits;
  return code;
}
Bool I386CompactArcExpand(CI386CompactArc *c,CArcCompress *arc,U8 *output)
{
  I64 position=17<<3,limit=arc->compressed_size<<3,used=0;
  I64 last,code,base,length,count,last_ch;
  c->minimum=256;if(arc->compression_type==CT_7_BIT)c->minimum=128;
  c->bits=9;if(c->minimum==128)c->bits=8;
  c->free_idx=c->minimum;c->free_limit=1<<c->bits;c->pending=-1;
  if(!I386CompactArcEntry(c))return FALSE;
  last=I386CompactArcRead(arc,&position,limit,c->bits);
  if(last<0 || last>=c->minimum)return FALSE;
  output[used++]=last;last_ch=last;
  if(!I386CompactArcEntry(c))return FALSE;
  while(used<arc->expanded_size) {
    base=I386CompactArcRead(arc,&position,limit,c->bits);
    if(base<0 || c->current<c->minimum || c->current>=4096 ||
        I386CompactArcChain(c,last,c->current)<0)return FALSE;
    if(base==c->current)length=I386CompactArcChain(c,last,-1)+1;
    else length=I386CompactArcChain(c,base,-1);
    if(length<1 || length>4096 || length>arc->expanded_size-used)return FALSE;
    c->valid[c->current>>3]|=1<<(c->current&7);
    count=0;code=base;
    if(base==c->current){c->stack[count++]=last_ch;code=last;}
    while(code>=c->minimum){c->stack[count++]=c->suffix[code];code=c->prefix[code];}
    c->stack[count++]=code;last_ch=code;
    c->prefix[c->current]=last;c->suffix[c->current]=last_ch;
    c->next[c->current]=c->head[last];c->head[last]=c->current+1;
    if(!I386CompactArcEntry(c))return FALSE;
    while(count)output[used++]=c->stack[--count];
    last=base;
  }
  return limit-position<8;
}
