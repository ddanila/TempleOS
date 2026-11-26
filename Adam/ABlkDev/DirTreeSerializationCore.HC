I64 DirTreeSerializeSize(CDirEntry *tmpde)
{
  I64 res=0;
  while (tmpde) {
    res+=CDIR_SIZE+1;
    if (tmpde->attr & RS_ATTR_DIR)
      res+=DirTreeSerializeSize(tmpde->sub);
    tmpde=tmpde->next;
  }
  return res+1;
}
I64 DirTreeSerializeFill(CDirEntry *tmpde,U8 *dst)
{
  I64 res=0,i;
  while (tmpde) {
    *dst++=1;
    res++;
    MemCpy(dst,&tmpde->start,CDIR_SIZE);
    dst+=CDIR_SIZE;
    res+=CDIR_SIZE;
    if (tmpde->attr & RS_ATTR_DIR) {
      i=DirTreeSerializeFill(tmpde->sub,dst);
      dst+=i;
      res+=i;
    }
    tmpde=tmpde->next;
  }
  *dst=0;
  return res+1;
}
public U8 *DirTreeSerialize(CDirEntry *tmpde,I64 *_size=NULL)
{//Serialize tree returned from $LK,"FilesFind",A="MN:FilesFind"$() into a one contiguous U8 array.
  I64 size=DirTreeSerializeSize(tmpde);
  U8 *buf=MAlloc(size);
  DirTreeSerializeFill(tmpde,buf);
  if (_size) *_size=size;
  return buf;
}

U8 *DirTreeUnserialize2(U8 *src,CDirEntry **tmpde)
{
  CDirEntry *tmpde1;
  if (*src++) {
    tmpde1=CAlloc(sizeof(CDirEntry));
    *tmpde=tmpde1;
    MemCpy(&tmpde1->start,src,CDIR_SIZE);
    src+=CDIR_SIZE;
    if (tmpde1->attr & RS_ATTR_DIR)
      src=DirTreeUnserialize2(src,&tmpde1->sub);
    src=DirTreeUnserialize2(src,&tmpde1->next);
  } else
    *tmpde=NULL;
  return src;
}
public CDirEntry *DirTreeUnserialize(U8 *src)
{//Unserialize tree to make it like a tree returned from $LK,"FilesFind",A="MN:FilesFind"$().
  CDirEntry *tmpde=NULL;
  DirTreeUnserialize2(src,&tmpde);
  return tmpde;
}
