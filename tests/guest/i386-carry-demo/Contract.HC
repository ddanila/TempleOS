U0 CDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *CDFunction(U8 *name)
{
  CHashFun *fun=HashFind(name,Fs->hash_table,HTT_FUN);
  if(fun)return fun->exe_addr;
  return NULL;
}
U8 *CDCapture(CDoc *doc,I64 *size,U8 *name)
{
  U8 *data=DocSave(doc,size),*s=MStrPrint("EXPORT %s %X %X\n",name,data,*size);
  CDLog(s);Free(s);return data;
}
U0 CDCheck()
{
  I64 mask=0,*result=CAlloc(8),n1,n2;U8 *first,*second,*s,*churn;
  CDoc *put=DocPut,*doc=DocNew;Bool raw=Raw(OFF);
  U0 (*count)(),(*shift)(),(*branch)();
  Fs->put_doc=doc;ExeFile("::/Demo/Carry.HC");Fs->put_doc=put;
  first=CDCapture(doc,&n1,"carry-demo-initial.DD");DocDel(doc);
  count=CDFunction("BigCnt");shift=CDFunction("BigShift");branch=CDFunction("Branch");
  if(count && shift && branch) {
    mask|=1;
    churn=MAlloc(32768);MemSet(churn,0xA5,32768);Free(churn);
    churn=MAlloc(32768,Fs->code_heap);MemSet(churn,0x5A,32768);Free(churn);
    doc=DocNew;Fs->put_doc=doc;(*count)();(*shift)();(*branch)();Fs->put_doc=put;
    second=CDCapture(doc,&n2,"carry-demo-retained.DD");DocDel(doc);
    if(n1==n2 && !MemCmp(first,second,n1))mask|=2;
    if(n1>0 && n2>0)mask|=4;
  }
  Raw(raw);*result=mask;s=MStrPrint("EXPORT carry-demo-mask.bin %X 8\n",result);CDLog(s);Free(s);
  CDLog("CARRY DEMO DONE\n");Sleep(1000);
}
CDCheck;
