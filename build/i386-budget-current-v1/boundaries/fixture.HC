U64 bc_data[16384];I64 bc_size;
U0 BCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 BCCase(I64 id,I64 kind,U8 *first,U8 *last,F64 period,Bool periodic)
{
  CBgtTemplate *t=CAlloc(sizeof(CBgtTemplate));CBgtEntry *e,*next;U64 *p=&bc_data[bc_size],*count;I64 n=0;
  QueInit(&b_head);QueInit(&t_head);t->type=kind;StrCpy(t->start_date,first);StrCpy(t->end_date,last);t->period=period;
  t->b.amount=100;t->b.credit=StrNew("BANK");t->b.debit=StrNew("RENT");t->b.desc=StrNew("boundary");
  BgtTemplateExpand(t,periodic);
  *p++=id;*p++=kind;*p++=periodic;count=p++;*count=0;
  for(e=b_head.next;e!=&b_head;e=e->next) {
    if(++n>64)throw('BCBound',TRUE);
    *p++=e->date;*p++=e->type;*p++=e->flags;*p++=e->amount(U64);
    *p++=(e->template==t)+2*(e->credit==t->b.credit)+4*(e->debit==t->b.debit)+8*(e->desc==t->b.desc);
    *p++=!StrCmp(e->credit,"BANK") && !StrCmp(e->debit,"RENT") && !StrCmp(e->desc,"boundary");
    *p++=e->last->next==e && e->next->last==e;
  }
  *count=n;bc_size=p-bc_data;
  if(periodic)for(e=b_head.next;e!=&b_head;e=next) {next=e->next;QueRem(e);BgtEntryDel(e);}
  BgtTemplateDel(t);
  if(b_head.next!=&b_head || b_head.last!=&b_head)throw('BCLeak',TRUE);
}
U0 BoundaryContract()
{
  I64 copy;U8 *line;
  bc_size=0;
  for(copy=0;copy<2;copy++) {
    BCCase(0,2,"01/31/1999","05/31/1999",0,copy);
    BCCase(1,3,"12/31/1999","06/30/2000",0,copy);
    BCCase(2,4,"08/31/1999","08/31/2000",0,copy);
    BCCase(3,5,"02/29/2000","03/01/2003",0,copy);
    BCCase(4,2,"02/01/2000","01/31/2000",0,copy);
    BCCase(5,2,"01/31/2000","01/31/2000",0,copy);
    BCCase(6,0,"01/01/2000","01/03/2000",1,copy);
    BCCase(7,1,"01/01/2000","01/03/2000",0.5,copy);
    BCCase(8,5,"01/01/2051","01/01/2053",0,copy);
  }
  line=MStrPrint("EXPORT boundaries.bin %X %X\n",bc_data,bc_size*8);BCLog(line);Free(line);BCLog("DONE Budget boundaries\n");
}
