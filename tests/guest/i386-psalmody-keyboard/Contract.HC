CTask *pk_parent;
I64 pk_stage,pk_mask,pk_notes[13],pk_deleted[9];
U0 PKLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 PKCount()
{
  PsmNote *n=psm.head.next;I64 count=0;
  while(n && n!=&psm.head) {count++;n=n->next;}
  return count;
}
U0 PKCapture(I64 *data)
{
  PsmNote *n=psm.head.next;I64 i=1;
  data[0]=PKCount;
  while(n!=&psm.head) {
    data[i++]=n->type;data[i++]=n->ona;data[i++]=n->duration;data[i++]=n->flags;
    n=n->next;
  }
}
U0 PKWatch(U8 *)
{
  while(pk_parent->draw_it!=&DrawIt || !psm.record_entry)Sleep(1);
  PKLog("PS ready\n");
  while(!psm.record_entry->checked)Sleep(1);
  PKLog("PS recording\n");
  while(PKCount!=1)Sleep(1);PKLog("PS note 1\n");
  while(PKCount!=2)Sleep(1);PKLog("PS note 2\n");
  while(PKCount!=3)Sleep(1);PKCapture(pk_notes);PKLog("PS note 3\n");
  while(PKCount!=2)Sleep(1);PKCapture(pk_deleted);
  pk_stage=1;PKLog("PS deleted\n");
}
U0 PsalmodyKeyboard()
{
  CTask *watcher;I64 watch_num;
  CDoc *put=Fs->put_doc,*display=Fs->display_doc;
  I64 form=put->flags&DOCF_FORM;
  U8 *draw=Fs->draw_it;
  CMenu *menu=Fs->cur_menu;
  CTaskSettings *settings=Fs->next_settings;
  CCtrl *ctrl=Fs->next_ctrl;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  pk_parent=Fs;pk_stage=pk_mask=0;
  watcher=Spawn(&PKWatch,NULL,"Psalmody observer");
  if(!watcher)throw('PSWatch',TRUE);
  watch_num=watcher->task_num;WinFocus(Fs);Psalmody;
  while(TaskValidate(watcher) && watcher->task_num==watch_num)Yield;
  if(pk_stage==1)pk_mask|=1;
  if(Fs->put_doc==put && Fs->display_doc==display && (put->flags&DOCF_FORM)==form)pk_mask|=2;
  if(Fs->draw_it==draw)pk_mask|=4;
  if(Fs->cur_menu==menu && Fs->next_settings==settings)pk_mask|=8;
  if(Fs->next_ctrl==ctrl)pk_mask|=16;
  if(Fs->win_left==left && Fs->win_right==right && Fs->win_top==top && Fs->win_bottom==bottom)pk_mask|=32;
  PKLog(MStrPrint("EXPORT notes.bin %X %X\n",pk_notes,sizeof(pk_notes)));
  PKLog(MStrPrint("EXPORT deleted.bin %X %X\n",pk_deleted,sizeof(pk_deleted)));
  PKLog(MStrPrint("EXPORT mask.bin %X 8\n",&pk_mask));PKLog("PS done\n");
}
