#include "C:/Probe/MouseQueueCore.HC"
class CMouseQueueProbeGuard {I64 before;CMouseQueueProbeEvents queue;I64 after;};
I64 mq_mask,mq_initial[5];
U0 MQLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool MQEvent(CMouseQueueProbeEvent *e,I64 x,I64 y,I64 stamp,I64 buttons,Bool edge)
{return e->x==x && e->y==y && e->stamp==stamp && e->buttons==buttons && e->transition==edge;}
U0 MouseQueueContract()
{
  CMouseQueueProbeGuard guard;
  CMouseQueueProbeEvents *q=&guard.queue;
  CMouseQueueProbeEvent e;
  I64 i,before=Fs->data_heap->used_u8s;Bool okay;U8 *line;
  MouseGet(&mq_initial[0],&mq_initial[1],&mq_initial[2]);
  mq_initial[3]=ms.pos.x;mq_initial[4]=ms.pos.y;
  guard.before=0x123456789ABCDEF;guard.after=0x3456789ABCDEF01;mq_mask=0;
  MemSet(q,0,sizeof(CMouseQueueProbeEvents));MemSet(&e,0xA5,sizeof(CMouseQueueProbeEvent));
  if(!MouseQueueProbePop(q,&e) && e.x==0xA5A5A5A5A5A5A5A5)mq_mask|=1;
  MouseQueueProbePush(q,100,200,0,10);MouseQueueProbePush(q,102,204,0,11);
  if(q->count==1 && MouseQueueProbePop(q,&e) && MQEvent(&e,102,204,11,0,FALSE) && !q->count)mq_mask|=2;
  MouseQueueProbePush(q,10,10,1,20);MouseQueueProbePush(q,11,12,1,21);MouseQueueProbePush(q,12,14,1,22);MouseQueueProbePush(q,13,15,0,23);
  okay=q->count==3 && MouseQueueProbePop(q,&e) && MQEvent(&e,10,10,20,1,TRUE);
  okay=okay && MouseQueueProbePop(q,&e) && MQEvent(&e,12,14,22,1,FALSE);
  okay=okay && MouseQueueProbePop(q,&e) && MQEvent(&e,13,15,23,0,TRUE) && !q->count;
  if(okay)mq_mask|=4;
  MouseQueueProbePush(q,1,2,2,30);MouseQueueProbePush(q,3,4,3,31);MouseQueueProbePush(q,5,6,2,32);MouseQueueProbePush(q,7,8,0,33);
  okay=q->count==4;
  for(i=0;i<4;i++) {
    if(!MouseQueueProbePop(q,&e) || !MQEvent(&e,1+2*i,2+2*i,30+i,(0x232>>(i*4))&15,TRUE))okay=FALSE;
  }
  if(okay && !q->count)mq_mask|=8;
  okay=TRUE;
  for(i=0;i<200;i++) {
    MouseQueueProbePush(q,i,2*i,(i+1)&1,100+i);
    if(q->count!=1 || !MouseQueueProbePop(q,&e) || !MQEvent(&e,i,2*i,100+i,(i+1)&1,TRUE) || q->count || q->losses)okay=FALSE;
  }
  if(okay)mq_mask|=16;
  MemSet(q,0,sizeof(CMouseQueueProbeEvents));
  for(i=0;i<64;i++)MouseQueueProbePush(q,i,i,(i+1)&1,1000+i);
  if(q->count==64 && !q->losses)mq_mask|=32;
  MouseQueueProbePush(q,64,64,1,1064);
  if(q->losses==1 && q->count==1 && MouseQueueProbePop(q,&e) && MQEvent(&e,64,64,1064,1,TRUE) && !q->count)mq_mask|=64;
  if(guard.before==0x123456789ABCDEF && guard.after==0x3456789ABCDEF01 && Fs->data_heap->used_u8s==before)mq_mask|=128;
  if(mq_initial[0]==320 && mq_initial[1]==240 && !mq_initial[2] && mq_initial[3]==320 && mq_initial[4]==240)mq_mask|=256;
  line=MStrPrint("EXPORT initial-mouse.bin %X 28\n",mq_initial);MQLog(line);Free(line);
  line=MStrPrint("EXPORT queue-mask.bin %X 8\n",&mq_mask);MQLog(line);Free(line);
}
