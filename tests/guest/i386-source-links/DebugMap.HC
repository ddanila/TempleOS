I64 SLTarget(){return 42;}
I64 JRContract(U8 *expected)
{
  I64 base=Fs->data_heap->used_u8s,mask=0;
  CHashSrcSym *fun=HashFind("SLTarget",Fs->hash_table,HTT_FUN);
  CDbgInfo *saved=fun->dbg_info;
  CDbgInfo *map=CAlloc(offset(CDbgInfo.body)+4*sizeof(U32));
  U8 *addr=&SLTarget,*filename,*link,*want;
  map->min_line=10;map->max_line=12;
  map->body[0]=addr;map->body[2]=addr+4;map->body[3]=addr+8;
  fun->dbg_info=map;
  if(SrcLineNum(addr)==10)mask|=1;
  if(SrcLineNum(addr+2,4)==12)mask|=2;
  filename=SrcFileName(addr+2,4);
  if(filename && !StrCmp(filename,expected))mask|=4;
  link=SrcEdLink(addr+2,4);want=MStrPrint("FL:%s,12",expected);
  if(link && !StrCmp(link,want))mask|=8;
  Free(filename);Free(link);Free(want);
  map->body[0]=0;map->body[2]=0;
  if(SrcLineNum(addr)==-1)mask|=16;
  fun->dbg_info=saved;Free(map);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
