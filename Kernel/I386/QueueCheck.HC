//Run unchanged against original x64 intrinsics and native public declarations.
class CQueueCheckNode:CQue { I64 marker; };
I64 QueueCheck()
{
  CQueueCheckNode h,a,b,c;
  CQue *entry,*pred;
  I64 i;
  h.marker=a.marker=b.marker=c.marker=0x1234567887654321;
  QueInit(&h); QueInit(&a); QueInit(&b); QueInit(&c);
  if(h.next!=&h || h.last!=&h || a.next!=&a || a.last!=&a) return -1;
  QueRem(&h);
  if(h.next!=&h || h.last!=&h) return -2;
  QueIns(&a,&h);
  if(h.next!=&a || h.last!=&a || a.next!=&h || a.last!=&h) return -3;
  QueIns(&b,&a); QueInsRev(&c,&b);
  if(h.next!=&a || h.last!=&b || a.next!=&c || a.last!=&h ||
      c.next!=&b || c.last!=&a || b.next!=&h || b.last!=&c) return -4;
  QueRem(&c);
  if(a.next!=&b || b.last!=&a || c.next!=&b || c.last!=&a) return -5;
  QueRem(&a); QueRem(&b);
  if(h.next!=&h || h.last!=&h) return -6;
  entry=&a; pred=&h;
  QueIns(entry++,pred++);
  if(entry!=(&a)(CQue *)+1 || pred!=(&h)(CQue *)+1 || h.next!=&a || a.last!=&h) return -7;
  QueRem(&a);
  for(i=0;i<32;i++) {
    QueInsRev(&b,&h); QueInsRev(&c,&b); QueRem(&b); QueRem(&c);
    if(h.next!=&h || h.last!=&h) return -8;
  }
  if(h.marker!=0x1234567887654321 || a.marker!=h.marker ||
      b.marker!=h.marker || c.marker!=h.marker) return -9;
  return 9;
}
