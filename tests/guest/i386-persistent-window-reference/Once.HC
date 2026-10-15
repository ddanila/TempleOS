U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PGExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(s);Free(s);}
U0 PGFinal(CDC *dc){dc->body[51280]=2;}
U0 (*pg_old_final)(CDC *dc);
U0 CapturePersistent()
{
  CDoc *d=DocPut;
  I64 *v=CAlloc(64),old_attr=Fs->text_attr,old_display=Fs->display_flags,
      old_inhibit=Fs->win_inhibit,old_l=Fs->win_left,old_r=Fs->win_right,
      old_t=Fs->win_top,old_b=Fs->win_bottom,old_pixel=gr.dc->body[51280];
  pg_old_final=gr.fp_final_scrn_update;
  DocRst(d,TRUE);d->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  Fs->text_attr=0xF0;DocPrint(d,"Plain\n");
  Fs->display_flags|=1<<DISPLAYf_SHOW|1<<DISPLAYf_NO_BORDER;
  Fs->win_inhibit&=~1025;WinHorz(0,79);WinVert(0,59);WinToTop;
  gr.dc->body[51280]=4;Refresh(3);
  v[0]=gr.dc2->body[51280];v[1]=gr.text_base[0]&0xFFFF;
  gr.dc->body[51280]=1;gr.fp_final_scrn_update=&PGFinal;Refresh(3);
  v[2]=gr.dc2->body[51280];v[3]=gr.text_base[0]&0xFFFF;
  gr.fp_final_scrn_update=NULL;Refresh(3);
  v[4]=gr.dc2->body[51280];v[5]=gr.text_base[0]&0xFFFF;
  gr.dc->body[51280]=TRANSPARENT;Refresh(3);
  v[6]=gr.dc2->body[51280];v[7]=gr.text_base[0]&0xFFFF;
  gr.dc->body[51280]=old_pixel;gr.fp_final_scrn_update=pg_old_final;
  Fs->text_attr=old_attr;Fs->display_flags=old_display;Fs->win_inhibit=old_inhibit;
  WinHorz(old_l,old_r);WinVert(old_t,old_b);
  PGExport("persistent-window.bin",v,64);
}
CapturePersistent;
Report("DONE original persistent window layering\n");
