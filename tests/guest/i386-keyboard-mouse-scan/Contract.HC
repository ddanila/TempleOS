I64 km_rows[8][2][5],km_mask;
U0 KMLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 KeyboardMouseScan()
{
  CDoc *put=DocPut,*display=DocDisplay,*doc;CTask *focus=sys_focus_task;
  I64 before=Fs->data_heap->used_u8s,flags=Fs->display_flags,inhibit=Fs->win_inhibit;
  I64 x=ms.pos.x,y=ms.pos.y,z=ms.pos.z,lb=ms.lb,rb=ms.rb;
  I64 phase,index,deadline,code,ch,scan,*row;U8 *s;
  Bool ac=AutoComplete(FALSE),good=TRUE;
  km_mask=0;MemSet(km_rows,0,sizeof(km_rows));
  doc=DocNew("KeyboardMouseScan.DD");doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  DocPrint(doc,"Keyboard mouse scan flags\n");DocTop(doc);
  Fs->put_doc=Fs->display_doc=doc;LBts(&Fs->display_flags,DISPLAYf_SHOW);
  LBts(&Fs->display_flags,DISPLAYf_NOT_RAW);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Fs->win_inhibit&=~WIF_SELF_FOCUS;Fs->win_inhibit|=WIF_SELF_MS_L|WIF_SELF_MS_R;
  WinFocus(Fs);Sleep(250);
  for(phase=0;phase<8;phase++) {
    if(phase<4)MsSet(320,240,0,(phase&1)!=0,(phase&2)!=0);
    if(phase==4)MsSet(320,240,0,FALSE,FALSE);
    Sleep(600);FlushMsgs;
    s=MStrPrint("KM READY %d\n",phase);KMLog(s);Free(s);
    for(index=0;index<2;index++) {
      deadline=cnts.jiffies+20000;code=0;
      while(!code&&cnts.jiffies<deadline) {
        code=ScanMsg(&ch,&scan,(1<<MSG_KEY_DOWN)|(1<<MSG_KEY_UP));
        if(!code)Sleep(1);
      }
      if(!code)throw('KMWait',TRUE);
      row=km_rows[phase][index];row[0]=code;row[1]=ch;row[2]=scan;
      row[3]=kbd.scan_code;row[4]=ms.lb+2*ms.rb;
      if(!(GetRFlags&0x200))good=FALSE;
      s=MStrPrint("KM KEY %d %d\n",phase,index);KMLog(s);Free(s);
    }
  }
  KMLog("KM RELEASE\n");deadline=cnts.jiffies+20000;ch=0;
  while(ch!='q'&&cnts.jiffies<deadline){ScanKey(&ch);Sleep(10);}
  if(ch!='q')throw('KMWait',TRUE);
  Fs->put_doc=put;Fs->display_doc=display;DocDel(doc);Fs->display_flags=flags;Fs->win_inhibit=inhibit;
  MsSet(x,y,z,lb,rb);Sleep(250);
  if(TaskValidate(focus))WinFocus(focus);FlushMsgs;
  if(Fs->put_doc==put&&Fs->display_doc==display&&Fs->win_inhibit==inhibit)km_mask|=1;
  if(Fs->data_heap->used_u8s==before)km_mask|=2;
  if(good&&ms.pos.x==x&&ms.pos.y==y&&ms.pos.z==z&&ms.lb==lb&&ms.rb==rb)km_mask|=4;
  AutoComplete(ac);
  s=MStrPrint("EXPORT keyboard-mouse-scan.bin %X %X\n",km_rows,sizeof(km_rows));KMLog(s);Free(s);
  s=MStrPrint("EXPORT keyboard-mouse-mask.bin %X 8\n",&km_mask);KMLog(s);Free(s);KMLog("KM DONE\n");
}
