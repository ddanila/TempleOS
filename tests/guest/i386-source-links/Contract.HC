I64 SLTarget(){return 42;}
I64 JRContract(U8 *expected)
{
  I64 base=Fs->data_heap->used_u8s,mask=0,line;
  CHashSrcSym *fun=HashFind("SLTarget",Fs->hash_table,HTT_FUN);
  CDbgInfo *saved=fun->dbg_info;
  U8 *filename,*link,*want;
  fun->dbg_info=NULL;
  line=SrcLineNum(&SLTarget);
  filename=SrcFileName(&SLTarget);
  link=SrcEdLink(&SLTarget);
  want=MStrPrint("FL:%s,1",expected);
  if(line==1)mask|=1;
  if(filename && !StrCmp(filename,expected))mask|=2;
  if(link && !StrCmp(link,want))mask|=4;
  if(SrcLineNum(NULL)==-1 && !SrcFileName(NULL) && !SrcEdLink(NULL))mask|=8;
  fun->dbg_info=saved;
  Free(want);Free(link);Free(filename);
  if(Fs->data_heap->used_u8s==base)mask|=16;
  return mask;
}
