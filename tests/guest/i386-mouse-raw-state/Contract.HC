I64 mr_rows[6][8],mr_mask;
U0 MRLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 MRCapture(I64 phase)
{
  I64 *r=mr_rows[phase];
  if(!MouseGet(r,r+1,r+2,r+3))throw('RawMouse',TRUE);
  r[4]=ms.pos.x;r[5]=ms.pos.y;r[6]=ms.lb;r[7]=ms.rb;
}
U0 MouseRawStateContract()
{
  I64 phase,expected,before,deadline,x,y,b,p,guard=0x1234567,flags=GetRFlags;
  U8 *s;
  CDoc *put=DocPut,*display=DocDisplay,*doc;
  FlushMsgs;before=Fs->data_heap->used_u8s;mr_mask=0;
  doc=DocNew("MouseRawState.DD");doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  DocPrint(doc,"Mouse raw API\n");DocTop(doc);Fs->put_doc=Fs->display_doc=doc;
  if(!MouseGet(NULL,&guard) && guard==0x1234567 && !MouseGet(&guard,NULL) && guard==0x1234567)mr_mask|=1;
  MRCapture(0);
  for(phase=1;phase<6;phase++) {
    s=MStrPrint("MR READY %d\n",phase);MRLog(s);Free(s);
    expected=0;if(phase==2)expected=1;else if(phase==3)expected=3;else if(phase==4)expected=2;
    deadline=cnts.jiffies+20000;
    while(cnts.jiffies<deadline) {
      MouseGet(&x,&y,&b,&p);
      if(x==344 && y==256 && b==expected && p>mr_rows[phase-1][3] &&
          ms.pos.x==332 && ms.pos.y==248 && ms.lb+2*ms.rb==b)break;
      Sleep(10);
    }
    if(cnts.jiffies>=deadline)throw('RawWait',TRUE);
    MRCapture(phase);
  }
  Fs->put_doc=put;Fs->display_doc=display;DocDel(doc);FlushMsgs;
  if(Fs->put_doc==put && Fs->display_doc==display)mr_mask|=2;
  if(Fs->data_heap->used_u8s==before)mr_mask|=4;
  if((GetRFlags&0x200)==(flags&0x200))mr_mask|=8;
  s=MStrPrint("EXPORT mouse-raw-state.bin %X %X\n",mr_rows,sizeof(mr_rows));MRLog(s);Free(s);
  s=MStrPrint("EXPORT mouse-raw-mask.bin %X 8\n",&mr_mask);MRLog(s);Free(s);MRLog("MR DONE\n");
}
