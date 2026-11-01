I64 DirEntryCompareName(CDirEntry *e1,CDirEntry *e2)
{
  U8 buf1[CDIR_FILENAME_LEN],buf2[CDIR_FILENAME_LEN],
	buf3[CDIR_FILENAME_LEN],buf4[CDIR_FILENAME_LEN];
  I64 d1=0,d2=0;
  if (e1->attr & RS_ATTR_DIR)
    d1=1;
  if (e2->attr & RS_ATTR_DIR)
    d2=1;
  if (d1!=d2)
    return d2-d1;
  else {
    StrCpy(buf1,e1->name);
    StrCpy(buf2,e2->name);
    FileExtRem(buf1,buf3);
    FileExtRem(buf2,buf4);
    if (d1=StrCmp(buf3,buf4))
      return d1;
    return StrCmp(buf1,buf2);
  }
}

I64 DirEntryCompareClus(CDirEntry *e1,CDirEntry *e2)
{
  return e1->clus-e2->clus;
}

#define SK_NAME		0
#define SK_CLUS	1

U0 DirFilesSort(CDirEntry **_tmpde,I64 key)
{
  I64 i,cnt,*sort_buf;
  CDirEntry *tmpde=*_tmpde,*tmpde1;
  if (tmpde) {
    cnt=LinkedLstCnt(tmpde);
    if (cnt>1) {
      sort_buf=MAlloc(cnt*sizeof(I64));
      i=0;
      tmpde1=tmpde;
      while (tmpde1) {
	sort_buf[i++]=tmpde1;
	tmpde1=tmpde1->next;
      }
      switch [key] {
	case SK_NAME:
	  QSortI64(sort_buf,cnt,&DirEntryCompareName);
	  break;
	case SK_CLUS:
	  QSortI64(sort_buf,cnt,&DirEntryCompareClus);
	  break;
      }
      tmpde=sort_buf[0];
      *_tmpde=tmpde;
      for (i=0;i<cnt-1;i++) {
	tmpde1=sort_buf[i];
	tmpde1->next=sort_buf[i+1];
      }
      tmpde1=sort_buf[i];
      tmpde1->next=NULL;
      Free(sort_buf);

      tmpde1=tmpde;
      while (tmpde1) {
	if (tmpde1->sub)
	  DirFilesSort(&tmpde1->sub,key);
	tmpde1=tmpde1->next;
      }
    } else
      if (tmpde->sub)
	DirFilesSort(&tmpde->sub,key);
  }
}

