Bool FM(U8 *name,U8 *pattern,I64 flags,Bool wanted)
{
  I64 base=Fs->data_heap->used_u8s;
  Bool got=FilesFindMatch(name,pattern,flags);
  return got==wanted && Fs->data_heap->used_u8s==base;
}
I64 JRContract(I64 unused)
{
  I64 mask=0;
  if(FM("A.HC","*.HC",0,TRUE) && FM("a.hc","*.HC",0,FALSE))mask|=1;
  if(FM("C:/Dir/A.HC.Z",FILEMASK_SRC,0,TRUE) && FM("A.TXT",FILEMASK_SRC,0,FALSE))mask|=2;
  if(FM("C:/Dir/A.HC","C:/Dir/*.HC",0,TRUE) && FM("C:/Other/A.HC","C:/Dir/*.HC",0,FALSE))mask|=4;
  if(FM("A.HC","*;!A.*",0,FALSE) && FM("B.HC","*;!A.*",0,TRUE) && FM("A.HC","!A.*;*",0,FALSE))mask|=8;
  if(FM("A.HC","",0,FALSE) && FM("ABC.HC","A?C.*",0,TRUE) && FM("AXXXB.HC","A*B.*",0,TRUE))mask|=16;
  if(FM("A.TXT","*",FUF_JUST_TXT,TRUE) && FM("A.GR","*",FUF_JUST_TXT,FALSE) &&
     FM("A.DD","*",FUF_JUST_DD,TRUE) && FM("A.TXT","*",FUF_JUST_DD,FALSE) &&
     FM("A.IN","*",FUF_JUST_SRC,TRUE) && FM("A.DD","*",FUF_JUST_SRC,FALSE) &&
     FM("A.PRJ","*",FUF_JUST_AOT,TRUE) && FM("A.IN","*",FUF_JUST_AOT,FALSE) &&
     FM("A.HH","*",FUF_JUST_JIT,TRUE) && FM("A.PRJ","*",FUF_JUST_JIT,FALSE) &&
     FM("A.GR.Z","*",FUF_JUST_GR,TRUE) && FM("A.HC","*",FUF_JUST_GR,FALSE))mask|=32;
  return mask;
}
