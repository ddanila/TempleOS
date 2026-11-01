U8 fat_long_name_map[13]={
  offset(CFAT32DirEntryLong.name1),
  offset(CFAT32DirEntryLong.name1)+2,
  offset(CFAT32DirEntryLong.name1)+4,
  offset(CFAT32DirEntryLong.name1)+6,
  offset(CFAT32DirEntryLong.name1)+8,
  offset(CFAT32DirEntryLong.name2),
  offset(CFAT32DirEntryLong.name2)+2,
  offset(CFAT32DirEntryLong.name2)+4,
  offset(CFAT32DirEntryLong.name2)+6,
  offset(CFAT32DirEntryLong.name2)+8,
  offset(CFAT32DirEntryLong.name2)+10,
  offset(CFAT32DirEntryLong.name3),
  offset(CFAT32DirEntryLong.name3)+2
};

Bool DirLongNameFill(CDirEntry *tmpde,CFAT32DirEntryLong *de,I64 *xsum)
{
  I64 i;
  U8 *ptr=de;
  if (de->ord&0x40) {
    MemSet(tmpde,0,sizeof(CDirEntry));
    *xsum=de->xsum;
  } else if (de->type || de->zero || de->xsum!=*xsum) {
    MemSet(tmpde,0,sizeof(CDirEntry));
    *xsum=0;
    return FALSE;
  }
  switch (de->ord&0x3F) {
    case 1:
      for (i=0;i<13;i++)
	if (!(tmpde->name[i]=ptr[fat_long_name_map[i]]))
	  return TRUE;
      break;
    case 2:
      for (i=0;i<13;i++)
	if (!(tmpde->name[i+13]=ptr[fat_long_name_map[i]]))
	  return TRUE;
      break;
    case 3:
      for (i=0;i<11;i++)
	if (!(tmpde->name[i+26]=ptr[fat_long_name_map[i]]))
	  return TRUE;
      break;
  }
  return TRUE;
}

