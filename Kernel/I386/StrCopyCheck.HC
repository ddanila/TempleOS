//One behavioral corpus for original x64 StrCpy and the native provider.
Bool StrCopyCheck(U0 (*copy)(U8 *dst,U8 *src))
{
  U8 src[1030],dst[1030];
  I64 i,flags=GetRFlags;
  Bool valid=TRUE;
  SetRFlags(flags&~0x400);
  for(i=0;i<1030;i++) dst[i]=91;
  (*copy)(0,1); //A null destination must not read the source.
  (*copy)(dst+1,0);
  if(dst[0]!=91 || dst[1] || dst[2]!=91) valid=FALSE;
  (*copy)(dst+1,"");
  if(dst[0]!=91 || dst[1] || dst[2]!=91) valid=FALSE;
  src[0]=128; src[1]=255; src[2]=0; src[3]=65;
  (*copy)(dst+1,src);
  if(dst[0]!=91 || dst[1]!=128 || dst[2]!=255 || dst[3] || dst[4]!=91) valid=FALSE;
  (*copy)(dst+1,dst+1);
  if(dst[1]!=128 || dst[2]!=255 || dst[3] || dst[4]!=91) valid=FALSE;
  (*copy)(dst,dst+1); //Forward copy into an earlier overlapping destination.
  if(dst[0]!=128 || dst[1]!=255 || dst[2] || dst[4]!=91) valid=FALSE;
  for(i=0;i<1024;i++) src[i]=1+i%255;
  src[1024]=0;
  (*copy)(dst+1,src);
  for(i=0;i<1024;i++) if(dst[i+1]!=src[i]) valid=FALSE;
  if(dst[1025] || dst[1026]!=91 || GetRFlags&0x400) valid=FALSE;
  src[0]=0; src[1]=255; src[2]=128;
  dst[0]=dst[1]=dst[2]=dst[3]=dst[4]=91;
  SetRFlags(GetRFlags|0x400);
  (*copy)(dst+3,src+2);
  if(!(GetRFlags&0x400)) valid=FALSE;
  SetRFlags(GetRFlags&~0x400);
  if(dst[0]!=91 || dst[1] || dst[2]!=255 || dst[3]!=128 || dst[4]!=91) valid=FALSE;
  SetRFlags(flags);
  return valid;
}
