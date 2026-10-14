U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 CaptureRender()
{
  I64 *v=CAlloc(10*sizeof(I64)),old_attr=Fs->text_attr,at;
  CDoc *old_display=Fs->display_doc,*d=DocNew("Render.DD");
  U8 *msg;
  Fs->text_attr=0xF0;Fs->display_doc=d;
  d->flags|=DOCF_NO_SCROLL_BARS|DOCF_DO_FULL_REFRESH;
  DocPrint(d,"A$$FG,RED$$B$$FG$$C\tD\nE");
  v[0]=DocRecalc(d,RECALCt_TO_SCRN);
  at=Fs->win_top*80+Fs->win_left;
  v[1]=gr.text_base[at]&65535;v[2]=gr.text_base[at+1]&65535;
  v[3]=gr.text_base[at+2]&65535;v[4]=gr.text_base[at+8]&65535;
  v[5]=gr.text_base[at+80]&65535;
  v[6]=d->max_x>=8;v[7]=d->max_y>=1;
  v[8]=!d->owning_task&&!Bt(&d->locked_flags,DOClf_LOCKED);
  v[9]=DocRecalc(NULL);
  Fs->display_doc=old_display;Fs->text_attr=old_attr;DocDel(d);
  msg=MStrPrint("EXPORT doc-render.bin %X %X\n",v,10*sizeof(I64));Report(msg);Free(msg);
}
CaptureRender;
Report("DONE original document renderer\n");
