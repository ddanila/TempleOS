CDoc *ms_test_doc,*ms_test_display;
I64 ms_test_attr;
U0 MSTLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *MSTTag(CDoc *d,CDocEntry *e,CTask *t){return StrNew("A",t);}
U0 MSTSetup()
{
  CDocEntry *e;
  ms_test_attr=Fs->text_attr;ms_test_display=Fs->display_doc;
  ms_test_doc=DocNew("MouseState.DD");
  ms_test_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  Fs->text_attr=0xF0;
  e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;
  e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("");e->tag_cb=&MSTTag;
  DocInsEntry(ms_test_doc,e);Fs->display_doc=ms_test_doc;
}
U0 MSTFinish()
{
  Fs->display_doc=ms_test_display;Fs->text_attr=ms_test_attr;
  DocDel(ms_test_doc);NativeTextBaseRestore;
}
I64 MSTProbe()
{
  I64 result=0,t0=ms.timestamp,sc;
  MSTSetup;Sleep(100);MSTLog("MS TEST ready\n");
  while(ms.pos.x!=350 || ms.pos.y!=250)Sleep(10);
  if(ms.pos_text.x==43 && ms.pos_text.y==31 && ms.timestamp>t0 && ms.speed>0)result|=1;
  MSTLog("MS TEST motion\n");
  while(!ms.lb)Sleep(10);
  if(!ms.rb)result|=2;
  MSTLog("MS TEST left\n");
  while(!ms.rb)Sleep(10);
  if(ms.lb)result|=4;
  MSTLog("MS TEST right\n");
  GetKey(&sc);
  if((sc&(SCF_MS_L_DOWN|SCF_MS_R_DOWN))==(SCF_MS_L_DOWN|SCF_MS_R_DOWN))result|=32;
  MSTLog("MS TEST keyboard\n");
  while(ms.lb || ms.rb)Sleep(10);
  result|=8;
  ms.scale.x=0.5;ms.offset.x=7;
  ms_grid.snap=TRUE;ms_grid.x=16;ms_grid.y=16;ms_grid.x_offset=2;
  MSTLog("MS TEST snap ready\n");
  while(ms.presnap.x!=186 || ms.presnap.y!=262)Sleep(10);
  if(ms.pos.x==178 && ms.pos.y==256 && ms.pos_text.x==22 && ms.pos_text.y==32)result|=16;
  MSTLog("MS TEST snap\n");
  GetKey;
  ms.scale.x=1;ms.offset.x=0;ms_grid.snap=FALSE;
  ms_grid.x=ms_grid.y=8;ms_grid.x_offset=0;
  MSTFinish;MSTLog("MS TEST end\n");return result;
}
