U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 CaptureRender()
{
  I64 *v=CAlloc(18*sizeof(I64)),old_attr=Fs->text_attr,at;
  CDoc *old_display=Fs->display_doc,*d=DocNew("Render.DD");
  U8 *msg;
  Fs->text_attr=0xF0;Fs->display_doc=d;
  d->flags|=DOCF_NO_SCROLL_BARS|DOCF_DO_FULL_REFRESH;
  DocPrint(d,"A$$FG,RED$$B$$FG$$C\tD\nE\n$$UL,1$$UL$$UL,0$$\n$$IV,1$$IV$$IV,0$$\n$$BG,BLUE$$BG$$BG$$\n$$BK,1$$BL$$BK,0$$");
  v[0]=DocRecalc(d,RECALCt_TO_SCRN);
  at=Fs->win_top*80+Fs->win_left;
  v[1]=gr.text_base[at]&65535;v[2]=gr.text_base[at+1]&65535;
  v[3]=gr.text_base[at+2]&65535;v[4]=gr.text_base[at+8]&65535;
  v[5]=gr.text_base[at+80]&65535;
  v[6]=d->max_x>=8;v[7]=d->max_y>=1;
  v[8]=!d->owning_task&&!Bt(&d->locked_flags,DOClf_LOCKED);
  v[9]=DocRecalc(NULL);
  v[10]=gr.text_base[at+160]&65535;
  v[11]=(gr.text_base[at+160]&ATTRF_UNDERLINE)!=0;
  v[12]=gr.text_base[at+240]&65535;
  v[13]=(gr.text_base[at+240]&ATTRF_INVERT)!=0;
  v[14]=gr.text_base[at+320]&65535;
  v[15]=gr.text_base[at+400]&65535;
  v[16]=(gr.text_base[at+400]&ATTRF_BLINK)!=0;
  v[17]=(gr.text_base[at]&(ATTRF_BLINK|ATTRF_INVERT|ATTRF_UNDERLINE))==0;
  Fs->display_doc=old_display;Fs->text_attr=old_attr;DocDel(d);
  msg=MStrPrint("EXPORT doc-render-style.bin %X %X\n",v,18*sizeof(I64));Report(msg);Free(msg);
}
CaptureRender;
Report("DONE original document renderer\n");
