I64 bitmap_widths[4]={1,8,9,17},bitmap_heights[4]={1,2,3,2};
Bool BitmapBytesEqual(U8 *a,U8 *b,I64 count)
{
  I64 i;for(i=0;i<count;i++)if(a[i]!=b[i])return FALSE;
  return TRUE;
}
I64 BitmapDocContract(I64 drive)
{
  I64 i,j,bytes,mask=0;
  U8 *sprite,*name;
  CDC *dc;
  CDoc *doc,*old;
  CDocEntry *entry;
  Bool geometry=TRUE,copy=TRUE,tag=TRUE,ownership=TRUE;
  for(i=0;i<4;i++) {
    dc=DCNew(bitmap_widths[i],bitmap_heights[i]);
    bytes=dc->width_internal*dc->height;
    for(j=0;j<bytes;j++)dc->body[j]=(j*7+i)&255;
    sprite=DC2Sprite(dc);
    name=MStrPrint("%c:/bitmap%d.DATA",drive,i);
    if(FileWrite(name,sprite,18+bytes)<=0)geometry=FALSE;
    Free(name);
    doc=DocNew;
    if(i&1)entry=DocSprite(doc,sprite,"$$SP,\"bitmap\",BI=%d$$");
    else entry=DocSprite(doc,sprite);
    if(!entry || !entry->bin_data || entry->bin_data->size!=18+bytes)
      geometry=FALSE;
    else {
      if(!BitmapBytesEqual(entry->bin_data->data,sprite,18+bytes))copy=FALSE;
      if(entry->bin_data->data==sprite || entry->bin_data->use_cnt!=1 ||
          entry->bin_data->num!=1 || doc->cur_bin_num!=2)ownership=FALSE;
      if(i&1 && (!entry->bin_data->tag || StrCmp(entry->bin_data->tag,"bitmap")))tag=FALSE;
      MemSet(sprite,0,18+bytes);
      if(!entry->bin_data->data[0])copy=FALSE;
    }
    Free(sprite);DCDel(dc);DocDel(doc);
  }
  if(geometry)mask|=1;if(copy)mask|=2;if(tag)mask|=4;if(ownership)mask|=8;
  dc=DCNew(1,1);dc->body[0]=9;sprite=DC2Sprite(dc);
  old=Fs->put_doc;doc=DocNew;Fs->put_doc=doc;
  entry=DocSprite(,sprite);
  Fs->put_doc=old;
  if(entry && entry->bin_data && entry->bin_data->data[17]==9)mask|=16;
  Fs->put_doc=NULL;
  if(!DocSprite(,sprite))mask|=32;
  Fs->put_doc=old;
  Free(sprite);DCDel(dc);DocDel(doc);
  return mask;
}
