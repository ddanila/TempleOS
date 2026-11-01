Bool FAT32CDirFill(CDirEntry *tmpde,
	CFAT32DirEntry *de,CDate _local_time_offset)
{
  Bool res;
  if (*tmpde->name)
    res=TRUE;
  else
    res=FATFromName(tmpde->name,de->name);
  tmpde->clus=de->clus_lo+de->clus_hi<<16;
  tmpde->size=de->size;
  tmpde->attr=de->attr;
  tmpde->datetime=Dos2CDate(de->WrtTime,de->WrtDate)-_local_time_offset;
  return res;
}

