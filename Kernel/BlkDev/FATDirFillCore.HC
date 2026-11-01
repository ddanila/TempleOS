Bool FAT32DirFill(CFAT32DirEntry *de,
	CDirEntry *tmpde,I64 *_de_cnt,CDate _local_time_offset)
{//Fill up to 4 entries and store cnt of entries.
  I64 de_cnt=0,i,l,xsum,ord,slots,pos;
  U8 *ptr,dname[16];
  CFAT32DirEntryLong *ld=de;
  Bool res;

  if (_de_cnt) *_de_cnt=0;
  if (!FileNameChk(tmpde->name)) return FALSE;
  MemSet(de,0,sizeof(CFAT32DirEntry));
  res=FATNameTo(de->name,tmpde->name);
  FATFromName(dname,de->name);
  if (StrCmp(dname,tmpde->name)) {
    xsum=FATNameXSum(de->name);
    l=StrLen(tmpde->name);
    slots=(l+12)/13;
    for (ord=slots;ord>=1;ord--) {
      ptr=&ld[de_cnt];
      MemSet(ptr,0,sizeof(CFAT32DirEntryLong));
      ld[de_cnt].attr=RS_ATTR_LONG_NAME;
      ld[de_cnt].xsum=xsum;
      ld[de_cnt].ord=ord;
      if (ord==slots) ld[de_cnt].ord|=0x40;
      for (i=0;i<13;i++) {
        pos=(ord-1)*13+i;
        if (pos<l) ptr[fat_long_name_map[i]]=tmpde->name[pos];
        else if (pos>l) ptr[fat_long_name_map[i]](U16)=0xFFFF;
      }
      de_cnt++;
    }
    MemSet(&de[de_cnt],0,sizeof(CFAT32DirEntry));
    res=FATNameTo(de[de_cnt].name,tmpde->name);
  }
  de[de_cnt].clus_lo=tmpde->clus.u16[0];
  de[de_cnt].clus_hi=tmpde->clus.u16[1];
  if (!(tmpde->attr&RS_ATTR_DIR))
    de[de_cnt].size=tmpde->size;
  de[de_cnt].attr=tmpde->attr;
  if (!tmpde->datetime)
    tmpde->datetime=Now;
  CDate2Dos(&de[de_cnt].WrtTime,&de[de_cnt].WrtDate,
	tmpde->datetime+_local_time_offset);
  if (_de_cnt)
    *_de_cnt=de_cnt+1;
  return res;
}

