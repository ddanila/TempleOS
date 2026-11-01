Bool FWCase(U8 *name,I64 expected_count)
{
 U8 raw[132],decoded_name[48];CDirEntry src,decoded;I64 cnt=0,sum=0,i,expected_ord;
 Bool ok;MemSet(raw,0xA5,sizeof(raw));MemSet(&src,0,sizeof(src));MemSet(&decoded,0,sizeof(decoded));
 StrCpy(src.name,name);src.clus=0x123456;src.size=123;src.datetime=1;
 ok=FAT32DirFill(raw+1,&src,&cnt,0) && cnt==expected_count && raw[0]==0xA5 && raw[1+cnt*32]==0xA5;
 if(!ok)return FALSE;
 if(cnt==1) {
  if(!FATFromName(decoded_name,raw+1) || StrCmp(decoded_name,name))return FALSE;
 } else {
  for(i=0;i<cnt-1;i++) {
   expected_ord=cnt-1-i;if(!i)expected_ord|=0x40;
   if(raw[1+i*32]!=expected_ord || raw[1+i*32+11]!=15)return FALSE;
   if(!DirLongNameFill(&decoded,raw+1+i*32,&sum))return FALSE;
  }
  if(StrLen(name)==13 && raw[1+30]!='m')return FALSE;
  if(StrLen(name)==25 && (raw[1+28]!='y' || raw[1+30]!=0))return FALSE;
  if(StrLen(name)==26 && raw[1+30]!='z')return FALSE;
  if(StrLen(name)==37 && (raw[1+28]!=0 || raw[1+30]!=255 || raw[1+31]!=255))return FALSE;
  if(StrCmp(decoded.name,name) || sum!=FATNameXSum(raw+1+(cnt-1)*32))return FALSE;
 }
 return raw[1+(cnt-1)*32+28]==123 && raw[1+(cnt-1)*32+29]==0;
}
I64 FWContract(Bool extended)
{
 I64 mask=0;
 if(FWCase("FILE.TXT",1))mask|=1;
 if(FWCase("abcdefghijklm",2))mask|=2;
 if(FWCase("abcdefghijklmnopqrstuvwxy",3))mask|=4;
 if(extended && FWCase("abcdefghijklmnopqrstuvwxyz",3))mask|=8;
 if(extended && FWCase("abcdefghijklmnopqrstuvwxyz0123456789a",4))mask|=16;
 return mask;
}
