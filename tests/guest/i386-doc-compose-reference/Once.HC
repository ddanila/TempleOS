U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 cp_count=0;
U8 *CPTag(CDoc *d,CDocEntry *e,CTask *t)
{U8 s[2];s[0]=64+(++cp_count);s[1]=0;return StrNew(s,t);}
U0 CPEntries(CDoc *d)
{
  CDocEntry *e=CAlloc(sizeof(CDocEntry));
  CDocBin *b=CAlloc(sizeof(CDocBin));
  I64 size=sizeof(CSpriteColor)+sizeof(CSpritePtPt)+1;
  U8 *s=CAlloc(size);CSpriteColor *c=s;CSpritePtPt *r=s+sizeof(CSpriteColor);
  e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("");e->tag_cb=&CPTag;DocInsEntry(d,e);
  c->type=SPT_COLOR;c->color=BLUE;r->type=SPT_RECT;r->x1=-4;r->y1=2;r->x2=8;r->y2=6;
  b->num=1;b->size=size;b->use_cnt=1;b->data=s;QueIns(b,d->bin_head.last);
  e=CAlloc(sizeof(CDocEntry));e->type=DOCT_SPRITE;e->de_flags=DOCEF_TAG|DOCEF_HAS_BIN;
  e->tag=StrNew("");e->bin_num=1;e->bin_data=b;DocInsEntry(d,e);
}
U0 CPExport(U8 *name,U8 *data,I64 size)
{U8 *msg=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(msg);Free(msg);}
U0 CaptureCompose()
{
  CDoc *d=DocNew("Compose.DD");CDC *frame=DCNew(640,480),*old_frame;
  U32 *cells=CAlloc(19200),*old_cells;
  I64 *v=CAlloc(48),old_attr=Fs->text_attr,at,i,x,y,n;
  U8 *first=CAlloc(192),*second=CAlloc(192),*dst;
  frame->flags|=DCF_SCRN_BITMAP|DCF_ON_TOP;
  d->flags|=DOCF_NO_SCROLL_BARS;CPEntries(d);cp_count=0;
  for(i=0;i<4800;i++)cells[i]=0xF020;
  at=Fs->win_top*80+Fs->win_left;cells[at]=0xF050;
  PUSHFD
  CLI
  old_frame=gr.dc2;old_cells=gr.text_base;gr.dc2=frame;gr.text_base=cells;Fs->text_attr=0xF0;
  for(n=0;n<2;n++) {
    GrUpdateTextBG;GrUpdateTextFG;
    d->flags|=DOCF_DO_FULL_REFRESH;DocRecalc(d,RECALCt_TO_SCRN);
    v[n*2]=cp_count;v[n*2+1]=cells[at]&255;
    if(n)dst=second;else dst=first;
    for(y=0;y<8;y++)for(x=0;x<24;x++)dst[y*24+x]=frame->body[(Fs->pix_top+y)*640+Fs->pix_left+x];
  }
  gr.dc2=old_frame;gr.text_base=old_cells;Fs->text_attr=old_attr;
  POPFD
  v[4]=sizeof(CSpriteColor);v[5]=sizeof(CSpritePtPt);
  DocDel(d);DCDel(frame);Free(cells);
  CPExport("doc-compose.bin",v,48);CPExport("compose-first.bin",first,192);CPExport("compose-second.bin",second,192);
}
CaptureCompose;
Report("DONE original document composition\n");
