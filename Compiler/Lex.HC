#include "/Compiler/PublicControlCore.HC"

#include "/Compiler/PublicLexDocumentCore.HC"

#include "/Compiler/PublicLexCharCore.HC"

#include "/Compiler/LexSkipEolCore.HC"

U8 *LexFirstRem(CCmpCtrl *cc,U8 *marker,I64 _len=NULL)
{//$LK,"LexGetChar",A="MN:LexGetChar"$() chars making str until marker.
  U8 *res,*ptr;
  CQueVectU8 *tmpv=QueVectU8New;
  I64 i,len=0;
  while (TRUE) {
    i=LexGetChar(cc);
    if (!i||StrOcc(marker,i))
      break;
    QueVectU8Put(tmpv,len++,i);
  }
  if (i)
    Bts(&cc->flags,CCf_USE_LAST_U16);
  res=ptr=MAlloc(len+1);
  for (i=0;i<len;i++)
    *ptr++=QueVectU8Get(tmpv,i);
  *ptr=0;
  QueVectU8Del(tmpv);
  if (_len) *_len=len;
  return res;
}

#include "/Compiler/LexTokenCore.HC"
