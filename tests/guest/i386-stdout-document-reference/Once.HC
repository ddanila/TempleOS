U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 ar_calls=0;U8 ar_phase='A';
U8 *ARTag(CDoc *d,CDocEntry *e,CTask *t)
{U8 s[2];ar_calls++;s[0]=ar_phase;s[1]=0;return StrNew(s,t);}
U0 ARExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(s);Free(s);}
U0 CaptureAutomatic()
{
  CDoc *old_put=Fs->put_doc,*old_doc=Fs->display_doc,*d=DocNew("Automatic.DD");
  I64 *v=CAlloc(32),old_attr=Fs->text_attr,old_display=Fs->display_flags,
      old_inhibit=Fs->win_inhibit,old_l=Fs->win_left,old_r=Fs->win_right,
      old_t=Fs->win_top,old_b=Fs->win_bottom,x,y,before;
  U8 *first=CAlloc(64),*second=CAlloc(64);
  d->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  Fs->text_attr=0xF0;Fs->display_doc=Fs->put_doc=d;
  Fs->display_flags|=1<<DISPLAYf_SHOW|1<<DISPLAYf_NO_BORDER;
  Fs->win_inhibit&=~1025;WinHorz(0,79);WinVert(0,59);WinToTop;
  PutS("$$FG,");Bool partial=Bt(&d->flags,DOCf_IN_DOLLAR);PutS("RED$$A$$FG$$");
  Refresh(3);v[0]=partial&&(gr.text_base[0]&65535)==0xF441;v[1]=gr.text_base[0]&255;
  PUSHFD
  CLI
  for(y=0;y<8;y++)for(x=0;x<8;x++)first[y*8+x]=gr.dc2->body[y*640+x];
  POPFD
  PutChars(66);Refresh(3);v[2]=!(d->flags&DOCF_IN_DOLLAR)&&(gr.text_base[1]&65535)==0xF042;v[3]=gr.text_base[1]&255;
  PUSHFD
  CLI
  for(y=0;y<8;y++)for(x=0;x<8;x++)second[y*8+x]=gr.dc2->body[y*640+x+8];
  POPFD
  Fs->display_doc=old_doc;Fs->put_doc=old_put;Fs->text_attr=old_attr;Fs->display_flags=old_display;Fs->win_inhibit=old_inhibit;
  WinHorz(old_l,old_r);WinVert(old_t,old_b);DocDel(d);
  ARExport("doc-auto.bin",v,32);ARExport("auto-first.bin",first,64);ARExport("auto-second.bin",second,64);
}
CaptureAutomatic;
Report("DONE original automatic document refresh\n");
