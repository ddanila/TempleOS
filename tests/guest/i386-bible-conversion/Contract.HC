U0 BCMark(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 BibleConversionContract()
{
  U8 *name=NULL,*needle=NULL;I64 num=0,type,mask=0;
  BCMark("BC convert begin\n");
  type=EdLinkCvt("BF:Genesis,1:1",&name,&needle,&num);
  BCMark("BC convert end\n");
  if(type==8 && name && StrMatch("/Misc/Bible.TXT",name) && needle && !StrCmp(needle,"1:1") && num==297)mask|=1;
  BCMark("BC free name\n");Free(name);BCMark("BC free needle\n");Free(needle);
  name=NULL;needle=NULL;num=0;
  type=EdLinkCvt("BF:NoSuchBook,1:1",&name,&needle,&num);
  if(type==-1 && !name && needle && !StrCmp(needle,"1:1"))mask|=2;
  Free(name);Free(needle);BCMark("BC done\n");
  return mask;
}
