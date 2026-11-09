I64 mt_phase,mt_rows[16][2][17],mt_mask;
U0 MTLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 MTRow(I64 *r)
{
  r[0]=ms.pos.x;r[1]=ms.pos.y;r[2]=ms.pos.z;
  r[3]=ms.presnap.x;r[4]=ms.presnap.y;r[5]=ms.presnap.z;
  r[6]=ms.offset.x;r[7]=ms.offset.y;r[8]=ms.offset.z;
  r[9]=ms.pos_text.x;r[10]=ms.pos_text.y;r[11]=ms.pos_text.z;
  r[12]=ms.lb;r[13]=ms.rb;r[14]=Bt(&kbd.scan_code,SCf_MS_L_DOWN);
  r[15]=Bt(&kbd.scan_code,SCf_MS_R_DOWN);r[16]=ms.has_wheel;
}
U0 MTDefaults()
{
  ms.scale.x=ms.scale.y=ms.scale.z=1.0;
  ms.offset.x=ms.offset.y=ms.offset.z=0;GridInit;
}
U0 MouseSetContract()
{
  CGridGlbls old_grid;CD3 old_scale;CD3I64 old_offset;
  CDoc *put=DocPut,*display=DocDisplay,*doc;CTask *focus=sys_focus_task;
  I64 before=Fs->data_heap->used_u8s,flags=Fs->display_flags,inhibit=Fs->win_inhibit;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  I64 x=ms.pos.x,y=ms.pos.y,z=ms.pos.z,lb=ms.lb,rb=ms.rb;
  I64 ch,deadline,irq;U8 *s;
  Bool bordered=!Bt(&Fs->display_flags,DISPLAYf_NO_BORDER),ac_old=AutoComplete(FALSE);
  MemCpy(&old_grid,&ms_grid,sizeof(CGridGlbls));MemCpy(&old_scale,&ms.scale,sizeof(CD3));
  MemCpy(&old_offset,&ms.offset,sizeof(CD3I64));mt_mask=0;
  WinBorder(TRUE);WinHorz(10,65);WinVert(8,48);LBts(&Fs->display_flags,DISPLAYf_SHOW);
  LBts(&Fs->display_flags,DISPLAYf_NOT_RAW);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Fs->win_inhibit&=~WIF_SELF_FOCUS;Fs->win_inhibit|=WIF_SELF_MS_L|WIF_SELF_MS_R;
  doc=DocNew("MouseSet.DD");doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  DocPrint(doc,"Mouse set input\n");DocTop(doc);Fs->put_doc=Fs->display_doc=doc;WinFocus(Fs);
  MTDefaults;
  for(mt_phase=0;mt_phase<16;mt_phase++) {
    FlushMsgs;irq=GetRFlags;SetRFlags(irq&~0x200);
    switch(mt_phase) {
      case 0:MsSet(100,120,3,FALSE,FALSE);break;
      case 1:MsSet(,,,TRUE,FALSE);break;
      case 2:MsSet(,,,FALSE,TRUE);break;
      case 3:MsSet(-1,480,I64_MAX,2,-1);break;
      case 4:MsSet(639,479,-7,FALSE,FALSE);break;
      case 5:MsSet(0,0,0);break;
      case 6:
        ms.scale.x=2.0;ms.scale.y=0.5;ms.scale.z=2.0;
        ms.offset.x=7;ms.offset.y=-3;ms.offset.z=5;MsSet(101,83,19);break;
      case 7:MsSet(102,84,20);break;
      case 8:
        ms_grid.snap=TRUE;ms_grid.x=ms_grid.y=16;ms_grid.z=4;
        ms_grid.x_offset=2;ms_grid.y_offset=3;ms_grid.z_offset=-1;MsSet(107,92,24);break;
      case 9:MsSet;break;
      case 10:
        MTDefaults;ms_grid.x_speed=1.5;ms_grid.y_speed=2.5;ms_grid.z_speed=1.5;
        MsSet(101,103,7);break;
      case 11:MsSet(I64_MAX,I64_MAX);break;
      case 12:MTDefaults;MsSet(200,210,4,FALSE,FALSE);break;
      case 13:MsSet(300,310,10,TRUE,TRUE);break;
      case 14:MsSet(,,,TRUE,FALSE);break;
      case 15:MsSet(320,240,0,FALSE,FALSE);break;
    }
    MTRow(mt_rows[mt_phase][0]);SetRFlags(irq);
    s=MStrPrint("MT READY %d\n",mt_phase);MTLog(s);Free(s);
    deadline=cnts.jiffies+20000;ch=0;
    while(ch!='n' && cnts.jiffies<deadline){ScanKey(&ch);Sleep(10);}
    if(ch!='n')throw('SetWait',TRUE);Sleep(250);MTRow(mt_rows[mt_phase][1]);
  }
  Fs->put_doc=put;Fs->display_doc=display;DocDel(doc);Fs->win_inhibit=inhibit;
  WinBorder(bordered);WinHorz(left,right);WinVert(top,bottom);Fs->display_flags=flags;
  MemCpy(&ms_grid,&old_grid,sizeof(CGridGlbls));MemCpy(&ms.scale,&old_scale,sizeof(CD3));
  MemCpy(&ms.offset,&old_offset,sizeof(CD3I64));MsSet(x,y,z,lb,rb);
  if(TaskValidate(focus))WinFocus(focus);FlushMsgs;
  if(Fs->put_doc==put&&Fs->display_doc==display&&Fs->win_inhibit==inhibit)mt_mask|=1;
  if(Fs->data_heap->used_u8s==before)mt_mask|=2;
  if(ms.pos.x==x&&ms.pos.y==y&&ms.pos.z==z&&ms.lb==lb&&ms.rb==rb)mt_mask|=4;
  AutoComplete(ac_old);
  s=MStrPrint("EXPORT set-rows.bin %X %X\n",mt_rows,sizeof(mt_rows));MTLog(s);Free(s);
  s=MStrPrint("EXPORT set-mask.bin %X 8\n",&mt_mask);MTLog(s);Free(s);MTLog("MT DONE\n");
}
