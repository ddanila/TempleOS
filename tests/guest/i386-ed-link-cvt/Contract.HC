I64 ELTarget(){return 42;}
Bool ELC(U8 *link,I64 type,U8 *filename,U8 *needle,I64 num)
{
  I64 base=Fs->data_heap->used_u8s,actual_num=0,actual;
  U8 *actual_file=NULL,*actual_needle=NULL;
  actual=EdLinkCvt(link,&actual_file,&actual_needle,&actual_num);
  Bool ok=actual==type && actual_num==num;
  if(filename)ok=ok && actual_file && !StrCmp(actual_file,filename);
  else ok=ok && !actual_file;
  if(needle)ok=ok && actual_needle && !StrCmp(actual_needle,needle);
  else ok=ok && !actual_needle;
  Free(actual_file);Free(actual_needle);
  return ok && Fs->data_heap->used_u8s==base;
}
I64 JRContract(I64 drive)
{
  I64 mask=0,base,num;
  CHashDefineStr *alias;
  CHashSrcSym *fun;
  CDbgInfo *saved_dbg;
  U8 *saved_link,*bible,*scratch,*got_file=NULL,*got_needle=NULL;
  U8 *name=MStrPrint("%c:/NameAbs/Parent.HC",drive),*link;
  link=MStrPrint("FI:%s",name);if(ELC(link,0,name,NULL,1))mask|=1;Free(link);
  link=MStrPrint("FL:%s,17",name);if(ELC(link,3,name,NULL,17))mask|=2;Free(link);
  link=MStrPrint("FA:%s,Start",name);if(ELC(link,1,name,"Start",1))mask|=4;Free(link);
  link=MStrPrint("FF:%s,Target:3",name);if(ELC(link,2,name,"Target",3))mask|=8;Free(link);
  if(ELC("AL:123,17",15,"123",NULL,17))mask|=16;
  if(ELC("DN:word,2",9,"word",NULL,2))mask|=32;
  if(ELC("HI:Index",10,"Index",NULL,1))mask|=64;
  if(ELC("ZZ:any",-1,NULL,NULL,1))mask|=128;
  bible=FileNameAbs(BIBLE_FILENAME,FUF_Z_OR_NOT_Z);
  if(ELC("BF:Genesis,1:1-3",8,bible,"1:1",297))mask|=256;
  Free(bible);
  alias=DefineLoad("EL_SOURCE","unused");
  Free(alias->src_link);alias->src_link=MStrPrint("FL:%s,17",name);
  if(ELC("MN:EL_SOURCE",3,name,NULL,17) && ELC("MN:EL_MISSING",-1,NULL,NULL,1))mask|=512;
  HashRemDel(alias,Fs->hash_table);
  fun=HashFind("ELTarget",Fs->hash_table,HTT_FUN);
  saved_link=fun->src_link;saved_dbg=fun->dbg_info;
  fun->src_link=MStrPrint("FL:%s,17",name);fun->dbg_info=NULL;
  if(ELC("AD:&ELTarget,64",3,name,NULL,17) && ELC("AD:0",-1,NULL,NULL,1))mask|=1024;
  if(ELC("AD:&ELTarget",3,name,NULL,17))mask|=131072;
  Free(fun->src_link);fun->src_link=saved_link;fun->dbg_info=saved_dbg;
  scratch=FileNameAbs("~/Tmp.DD.Z",FUF_Z_OR_NOT_Z);
  base=Fs->data_heap->used_u8s;num=0;
  Bool bail=EdLinkCvt(NULL,&got_file,&got_needle,&num,EDF_BAIL)==-1 && !got_file && !got_needle && Fs->data_heap->used_u8s==base;
  if(bail && ELC(NULL,0,scratch,NULL,1) && ELC("",0,scratch,NULL,1))mask|=2048;
  Free(scratch);
  Bool variants=TRUE;
  link=MStrPrint("PI:%s",name);variants=variants && ELC(link,5,name,NULL,1);Free(link);
  link=MStrPrint("PF:%s,Needle:4",name);variants=variants && ELC(link,6,name,"Needle",4);Free(link);
  link=MStrPrint("PL:%s,19",name);variants=variants && ELC(link,7,name,NULL,19);Free(link);
  if(variants)mask|=4096;
  if(ELC("AI:123",12,"123",NULL,1) && ELC("AA:123,Start",13,"123","Start",1) && ELC("AF:123,Needle:4",14,"123","Needle",4))mask|=8192;
  link=MStrPrint("FF:%s,Needle",name);
  variants=ELC(link,2,name,"Needle",1);Free(link);
  link=MStrPrint("FL:%s",name);variants=variants && ELC(link,3,name,NULL,1);Free(link);
  bible=FileNameAbs(BIBLE_FILENAME,FUF_Z_OR_NOT_Z);
  if(variants && ELC("DN:word",9,"word",NULL,-1) && ELC("BF:Genesis",8,bible,NULL,297))mask|=16384;
  Free(bible);
  if(ELC("BF:NoSuchBook,1:1",-1,NULL,"1:1",1))mask|=32768;
  base=Fs->data_heap->used_u8s;
  variants=TRUE;
  I64 i;
  for(i=0;i<10;i++) {
    if(EdLinkCvt("AF:123,Needle:4")!=14)variants=FALSE;
    if(EdLinkCvt("BF:NoSuchBook,1:1")!=-1)variants=FALSE;
    num=0;
    if(EdLinkCvt("AL:123,17",NULL,NULL,&num)!=15 || num!=17)variants=FALSE;
  }
  if(variants && Fs->data_heap->used_u8s==base)mask|=65536;
  if(ELC(name,0,name,NULL,1))mask|=262144;
  Free(name);return mask;
}
