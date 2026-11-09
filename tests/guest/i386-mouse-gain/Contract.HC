I64 mg_phase,mg_count,mg_rows[64][12];
U0 MGLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 MouseGainContract(I64 count)
{
  I64 ch,deadline,last,stable,*r;U8 *s;
  F64 sx=ms.scale.x,sy=ms.scale.y,gx=ms_grid.x,gy=ms_grid.y,xs=ms_grid.x_speed;
  I64 ox=ms.offset.x,oy=ms.offset.y;F64 gox=ms_grid.x_offset,goy=ms_grid.y_offset;
  Bool snap=ms_grid.snap,ac_old=AutoComplete(FALSE);
  if(count<1 || count>64)throw('GainSize',TRUE);
  mg_count=count;MemSet(mg_rows,0,sizeof(mg_rows));
  for(mg_phase=0;mg_phase<count;mg_phase++) {
    if(mg_phase==count-4) {
      ms.scale.x=0.5;ms.offset.x=7;ms_grid.snap=TRUE;
      ms_grid.x=ms_grid.y=16;ms_grid.x_offset=2;ms_grid.y_offset=0;
    }
    FlushMsgs;s=MStrPrint("MG READY %d\n",mg_phase);MGLog(s);Free(s);
    deadline=cnts.jiffies+20000;ch=0;
    while(ch!='n' && cnts.jiffies<deadline){ScanKey(&ch);Sleep(10);}
    if(ch!='n')throw('GainWait',TRUE);
    last=ms.timestamp;stable=cnts.jiffies;
    while(cnts.jiffies<stable+200) {
      Sleep(10);
      if(last!=ms.timestamp){last=ms.timestamp;stable=cnts.jiffies;}
    }
    r=mg_rows[mg_phase];r[0]=ms.pos.x;r[1]=ms.pos.y;
    r[2]=ms.presnap.x;r[3]=ms.presnap.y;r[4]=ms.offset.x;r[5]=ms.offset.y;
    r[6]=ms.pos_text.x;r[7]=ms.pos_text.y;r[8]=ms_grid.snap;
    r[9]=ms.scale.x(U64);r[10]=ms.scale.y(U64);r[11]=ms.lb+2*ms.rb;
    s=MStrPrint("gain-step-%d.bin",mg_phase);
    U8 *line=MStrPrint("EXPORT %s %X 60\n",s,r);MGLog(line);Free(line);Free(s);
  }
  ms.scale.x=sx;ms.scale.y=sy;ms.offset.x=ox;ms.offset.y=oy;
  ms_grid.snap=snap;ms_grid.x=gx;ms_grid.y=gy;ms_grid.x_speed=xs;
  ms_grid.x_offset=gox;ms_grid.y_offset=goy;AutoComplete(ac_old);
  s=MStrPrint("EXPORT gain-rows.bin %X %X\n",mg_rows,count*12*8);MGLog(s);Free(s);MGLog("MG DONE\n");
}
