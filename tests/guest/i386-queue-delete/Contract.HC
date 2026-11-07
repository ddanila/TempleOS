U0 QDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
class QDHead {CQue queue;I64 canary;};
U0 QDFill(CQue *head,I64 count)
{
  CQue *node;
  while(count--){node=CAlloc(sizeof(CQue)+24);QueIns(node,head->last);}
}
U0 QDCheck()
{
  I64 *r=CAlloc(8*8),used=Fs->data_heap->used_u8s,i;
  QDHead head;CQue *first,*last;U8 *s;
  head.canary=0x123456789ABCDEF;QueInit(&head.queue);
  QueDel(&head.queue);r[0]=head.queue.next==&head.queue && head.queue.last==&head.queue && Fs->data_heap->used_u8s==used;
  QueDel(&head.queue,TRUE);r[1]=head.queue.next==&head.queue && head.queue.last==&head.queue && Fs->data_heap->used_u8s==used;
  QDFill(&head.queue,3);first=head.queue.next;last=head.queue.last;
  QueDel(&head.queue);r[2]=head.queue.next==first && head.queue.last==last && Fs->data_heap->used_u8s==used;
  QueInit(&head.queue);QDFill(&head.queue,5);QueDel(&head.queue,TRUE);
  r[3]=head.queue.next==&head.queue && head.queue.last==&head.queue && Fs->data_heap->used_u8s==used;
  for(i=0;i<256;i++){QDFill(&head.queue,1+i%7);QueDel(&head.queue,TRUE);}
  r[4]=head.queue.next==&head.queue && head.queue.last==&head.queue && Fs->data_heap->used_u8s==used;
  for(i=0;i<256;i++){QueInit(&head.queue);QDFill(&head.queue,1+i%7);QueDel(&head.queue);}
  r[5]=Fs->data_heap->used_u8s==used;
  r[6]=head.canary==0x123456789ABCDEF;
  r[7]=sizeof(I64)==8;
  s=MStrPrint("EXPORT queue-delete.bin %X 40\n",r);QDLog(s);Free(s);
  QDLog("QUEUE DELETE DONE\n");Sleep(1000);
}
QDCheck;
