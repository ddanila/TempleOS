//Native-only ownership contract. Addresses come from bounded module exports.
class CReadHeap {U8 *base;U32 size,used,peak,allocations,signature;};
Bool (*ReadInit)(CReadHeap *heap,U8 *base,I64 size);
Bool (*ReadFree)(CReadHeap *heap,U8 *data);
Bool (*ReadValid)(CReadHeap *heap);
I64 (*ReadSize)(CReadHeap *heap,U8 *data);
U8 *(*ReadCopy)(CReadHeap *heap,U8 *raw,I64 bytes,I64 attr,I64 *size);
U8 *(*ReadBridge)(CReadHeap *heap,U8 *name,I64 *size,I64 *attr);
U0 ReadRequire(Bool ok,I64 id)
{
  U8 *line;
  if(!ok) {
    line=MStrPrint("FAIL private read %d\n",id);
    while(*line)OutU8(0xE9,*line++);
    throw('ReadTest',TRUE);
  }
}
I64 PrivateReads(U8 *init,U8 *release,U8 *valid,U8 *requested,U8 *copy,U8 *bridge)
{
  CReadHeap h;
  U8 raw[4],*arena=MAlloc(65536),*p,*q,*packed;
  I64 size,attr,packed_size,i;
  Bool caught;
  CHashGeneric *entry;
  raw[0]=65;raw[1]=0;raw[2]=66;raw[3]=255;
  ReadInit=init;ReadFree=release;ReadValid=valid;ReadSize=requested;
  ReadCopy=copy;ReadBridge=bridge;
  ReadRequire(sizeof(CReadHeap)==24&&offset(CReadHeap.signature)==20,1);
  ReadRequire(ReadInit(&h,arena,65536),2);
  size=-1;p=ReadCopy(&h,raw,4,0,&size);
  ReadRequire(p&&size==4&&ReadSize(&h,p)==5&&p[0]==65&&p[1]==0&&p[2]==66&&p[3]==255&&p[4]==0,3);
  ReadRequire(ReadFree(&h,p)&&ReadValid(&h)&&!h.used&&!h.allocations,4);
  size=-1;p=ReadCopy(&h,raw,0,0,&size);
  ReadRequire(p&&size==0&&!p[0]&&ReadSize(&h,p)==1&&ReadFree(&h,p),5);
  packed=FileRead("C:/Probe/PrivatePacked.arc",&packed_size);
  ReadRequire(packed&&packed_size>=17,6);
  size=-1;p=ReadCopy(&h,packed,packed_size,0x400,&size);
  ReadRequire(p&&size==64&&ReadSize(&h,p)==65&&!p[64]&&p[0]==65&&!p[1]&&p[2]==255,7);
  for(i=3;i<64;i++)ReadRequire(p[i]==65,8);
  ReadRequire(ReadFree(&h,p),9);
  size=-1;p=ReadCopy(&h,packed,16,0x400,&size);
  ReadRequire(!p&&size==-1&&!h.used&&!h.allocations&&ReadValid(&h),10);
  Free(packed);
  ReadRequire(ReadInit(&h,arena,24),11);
  size=-1;p=ReadCopy(&h,raw,4,0,&size);
  ReadRequire(p&&size==4&&h.used==24&&h.allocations==1,12);
  size=-1;caught=FALSE;q=NULL;
  try {q=ReadCopy(&h,raw,4,0,&size);}
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  ReadRequire(!caught&&!q&&size==-1&&h.used==24&&h.allocations==1,13);
  ReadRequire(ReadFree(&h,p),14);
  size=-1;caught=FALSE;
  try {q=ReadCopy(&h,raw,0x100000000,0,&size);}
  catch {caught=Fs->except_ch=='OutMem';Fs->catch_except=TRUE;}
  ReadRequire(caught&&size==-1&&!h.used&&!h.allocations&&ReadValid(&h),15);
  ReadRequire(ReadInit(&h,arena,65536),16);
  ReadRequire(FileWrite("C:/Probe/PrivatePlain.BIN",raw,4,0x1122334455667788)>0,17);
  size=attr=-1;p=ReadBridge(&h,"C:/Probe/PrivatePlain.BIN",&size,&attr);
  ReadRequire(p&&size==4&&attr==0x800&&ReadSize(&h,p)==5&&p[3]==255&&!p[4],18);
  ReadRequire(ReadFree(&h,p)&&!h.used&&!h.allocations,19);
  size=attr=-1;p=ReadBridge(&h,"C:/Probe/PrivateAbsent.BIN",&size,&attr);
  ReadRequire(!p&&size==-1&&attr==-1&&!h.used&&!h.allocations,20);
  ReadRequire(FileWrite("C:/Probe/PrivateCache.BIN",raw,4,0x1122334455667788,0x200)>0,21);
  size=attr=-1;p=ReadBridge(&h,"C:/Probe/PrivateCache.BIN",&size,&attr);
  ReadRequire(p&&size==4&&attr==0&&ReadSize(&h,p)==5,22);
  p[0]=90;q=ReadBridge(&h,"C:/Probe/PrivateCache.BIN",&size,&attr);
  ReadRequire(q&&q!=p&&q[0]==65&&ReadFree(&h,q)&&ReadFree(&h,p),23);
  ReadRequire(ReadInit(&h,arena,24),24);
  p=ReadCopy(&h,raw,4,0,&size);ReadRequire(p!=NULL,25);
  size=attr=-1;caught=FALSE;q=NULL;
  try {q=ReadBridge(&h,"C:/Probe/PrivateCache.BIN",&size,&attr);}
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  ReadRequire(!caught&&!q&&size==-1&&attr==-1&&h.used==24&&h.allocations==1,26);
  ReadRequire(ReadFree(&h,p)&&ReadValid(&h)&&!h.used&&!h.allocations,27);
  entry=HashFind("C:/Probe/PrivateCache.BIN",adam_task->hash_table,HTT_FILE);
  ReadRequire(entry&&entry->user_data1==4,28);
  entry->user_data1=0x100000000;size=attr=-1;caught=FALSE;
  try {q=ReadBridge(&h,"C:/Probe/PrivateCache.BIN",&size,&attr);}
  catch {caught=Fs->except_ch=='OutMem';Fs->catch_except=TRUE;}
  entry->user_data1=4;
  ReadRequire(caught&&size==-1&&attr==-1&&!h.used&&!h.allocations&&ReadValid(&h),29);
  ReadRequire(HashRemDel(entry,adam_task->hash_table),30);
  Free(arena);
  packed="PASS private read ownership and failure\n";
  while(*packed)OutU8(0xE9,*packed++);
  "PASS private read ownership and failure\n";
  return 42;
}
