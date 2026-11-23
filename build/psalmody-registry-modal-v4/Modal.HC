CTask *rp_owner;
I64 rp_mouse[2],rp_points[16],rp_phase,rp_checked,rp_result[4];
U0 RPLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 RPExport(U8 *name,I64 *data,I64 size)
{
  U8 format[100];
  StrPrint(format,"EXPORT %s %X %X\n",name,data,size);
  RPLog(format);
}
U0 RPPoint(CDoc *doc,CDocEntry *entry,I64 *point)
{
  CTask *task=doc->win_task;
  point[0]=task->pix_left+task->scroll_x+
    (entry->x-doc->line_start_col+1)*FONT_WIDTH+FONT_WIDTH/2;
  point[1]=task->pix_top+task->scroll_y+
    (entry->y-doc->top_line_num)*FONT_HEIGHT+FONT_HEIGHT/2;
}
U0 RPTrack(U8 *)
{
  CTask *popup;
  CDoc *doc;
  CDocEntry *entry,*checkbox,*button;
  I64 phase=0,*point;
  U8 name[30];
  while(TRUE) {
    rp_mouse[0]=ms.pos.x;rp_mouse[1]=ms.pos.y;
    popup=rp_owner->popup_task;
    if(popup && TaskValidate(popup) && (doc=popup->display_doc) &&
        doc->desc=='Menu' && doc->win_task==popup) {
      checkbox=button=NULL;
      for(entry=doc->head.next;entry!=doc;entry=entry->next) {
        if(entry->type_u8==DOCT_CHECK_BOX)checkbox=entry;
        if(entry->type_u8==DOCT_BTTN)button=entry;
      }
      if(checkbox && button) {
        if(phase!=rp_phase) {
          phase=rp_phase;rp_checked=FALSE;
          point=rp_points+4*(phase-1);
          RPPoint(doc,checkbox,point);
          RPPoint(doc,button,point+2);
          StrPrint(name,"modal-%d.bin",phase);
          RPExport(name,point,32);
        }
        if(!rp_checked && checkbox->de_flags&DOCEF_CHECKED_COLLAPSED) {
          rp_checked=TRUE;
          RPLog("RP checked\n");
        }
      }
    }
    Sleep(1);
  }
}
U0 RegistryModal(Bool reopen=FALSE)
{
  CTask *track;
  U8 line[80];
  I64 bit=ARf_PSALMODY_JUKEBOX;
  rp_owner=Fs;
  rp_result[0]=sys_msg_flags[0];
  if(!reopen) {
    track=Spawn(&RPTrack,NULL,"Registry modal observer");
    if(!track)throw('RPTrack',TRUE);
    StrPrint(line,"RP mouse %X\n",rp_mouse);RPLog(line);
    rp_phase=1;
    RegOneTimePopUp(bit,"Registry modal contract");
    rp_result[1]=sys_msg_flags[0];
    rp_phase=2;
    RegOneTimePopUp(bit,"Registry modal contract");
    rp_result[2]=sys_msg_flags[0];
    rp_phase=3;
    RegOneTimePopUp(bit,"Registry modal contract");
    rp_result[3]=sys_msg_flags[0];
  }
  rp_phase=4;
  RegOneTimePopUp(bit,"Suppression failed");
  if(!reopen)Kill(track);
  if(reopen) RPExport("flags.bin",rp_result,8);
  else RPExport("flags.bin",rp_result,sizeof(rp_result));
  RPLog("RP done\n");
}
