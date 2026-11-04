U0 ISODescriptorTypesContract()
{
  U8 bytes[2044];I64 i;CISOPriDesc *d=bytes;
  //Layout observed on the rebuilt original in i386-iso-init-reference-v1.
  if(sizeof(CPalindromeU16)!=4||sizeof(CPalindromeU32)!=8)throw('ISOType1',TRUE);
  if(sizeof(CISODirEntry)!=34||sizeof(CISOPriDesc)!=2044)throw('ISOType2',TRUE);
  if(offset(CISOPriDesc.root_dir_record)!=152||offset(CISOPriDesc.publisher_id)!=314)throw('ISOType3',TRUE);
  if(offset(CISOPriDesc.file_structure_version)!=877)throw('ISOType4',TRUE);
  for(i=0;i<2044;i++)bytes[i]=i;
  if(d->type||d->id[0]!=1||d->id[4]!=5||d->version!=6)throw('ISOType5',TRUE);
  if(d->vol_space_size.little!=0x53525150||d->vol_space_size.big!=0x57565554)throw('ISOType6',TRUE);
  if(d->log_block_size.little!=0x8180||d->log_block_size.big!=0x8382)throw('ISOType7',TRUE);
  if(d->root_dir_record.loc.little!=0x9D9C9B9A||d->root_dir_record.loc.big!=0xA1A09F9E)throw('ISOType8',TRUE);
  if(d->publisher_id[0]!=58||d->file_structure_version!=109)throw('ISOType9',TRUE);
}
ISODescriptorTypesContract;
