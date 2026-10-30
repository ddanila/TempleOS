I64 DocumentIrqDelete(U8 *path)
{
  CDoc *doc;I64 before,mask=0;U32 flags=GetRFlags,after;
  //Warm document services and file caches before measuring task ownership.
  doc=DocRead(path);if(!doc)return 0;DocDel(doc);
  before=Fs->data_heap->used_u8s;
  doc=DocRead(path);if(!doc)return 0;
  if(Fs->data_heap->used_u8s>before)mask|=1;
  SetRFlags(flags&~0x200);DocDel(doc);after=GetRFlags;
  SetRFlags(flags);
  if(!(after&0x200) && (GetRFlags&0x200)==(flags&0x200))mask|=2;
  if(Fs->data_heap->used_u8s==before)mask|=4;
  doc=DocRead(path);if(!doc)return mask;
  SetRFlags(flags|0x200);DocDel(doc);after=GetRFlags;
  SetRFlags(flags);
  if((after&0x200) && (GetRFlags&0x200)==(flags&0x200) &&
      Fs->data_heap->used_u8s==before)mask|=8;
  return mask;
}
