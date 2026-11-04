U0 FATMediaTypesContract()
{
  U8 bytes[512];I64 i;CFAT32Boot *br=bytes;CFAT32FileInfoSect *fis=bytes;
  if(sizeof(CFAT32Boot)!=512||sizeof(CFAT32FileInfoSect)!=512)throw('FType1',TRUE);
  if(offset(CFAT32Boot.sects_per_fat)!=36||offset(CFAT32Boot.root_clus)!=44||offset(CFAT32Boot.signature)!=510)throw('FType2',TRUE);
  if(offset(CFAT32FileInfoSect.signature2)!=484||offset(CFAT32FileInfoSect.most_recently_alloced)!=492||offset(CFAT32FileInfoSect.signature3)!=508)throw('FType3',TRUE);
  for(i=0;i<512;i++)bytes[i]=i;
  if(br->bytes_per_sect!=0x0C0B||br->sects_per_fat!=0x27262524||br->root_clus!=0x2F2E2D2C||br->signature!=0xFFFE)throw('FType4',TRUE);
  if(fis->signature2!=0xE7E6E5E4||fis->most_recently_alloced!=0xEFEEEDEC||fis->signature3!=0xFFFEFDFC)throw('FType5',TRUE);
}
FATMediaTypesContract;
