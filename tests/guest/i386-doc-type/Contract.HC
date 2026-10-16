I64 DTBusy(I64 base)
{
  I64 saved=cnts.HPET_freq,frequency,start,delta,mask=0;
  U32 *config=(base+0x10)(U32 *),period=*(base+4)(U32 *),old_config=*config;
  U8 pic=InU8(0x21);
  cnts.HPET_freq=0;Busy(0);Busy(-1);Busy(16);PortNop;
  if(InU8(0x21)==pic)mask|=1;
  cnts.HPET_freq=saved;
  if(!period || period==U32_MAX)return mask;
  frequency=1000000000000000/period;
  *config=old_config|1;cnts.HPET_freq=frequency;
  start=HPET;Busy(1000);delta=HPET-start;
  if(delta>=frequency/1000)mask|=2;
  Busy(0);
  *config=old_config;cnts.HPET_freq=saved;
  if(*config==old_config && cnts.HPET_freq==saved)mask|=4;
  return mask;
}
I64 DTSeed(I64 drive)
{
  I64 size,ok=0;
  U8 *name,*data,*plain="alpha\tbeta\nsecond\n",*markup="$$WW+H,1$$$$FG,4$$red$$FG$$\n";
  name=MStrPrint("%c:/T.TXT",drive);
  if(FileWrite(name,plain,StrLen(plain))>0)ok|=1;Free(name);
  name=MStrPrint("%c:/M.DD",drive);
  if(FileWrite(name,markup,StrLen(markup))>0)ok|=2;Free(name);
  name=MStrPrint("%c:/load3.DATA",drive);data=FileRead(name,&size);Free(name);
  name=MStrPrint("%c:/G.GR",drive);
  if(data && FileWrite(name,data,size)>0)ok|=4;
  Free(data);Free(name);return ok;
}
I64 DTDocuments(I64 drive)
{
  I64 i,size,mask=0,signature;
  U8 *name,*saved,*target;
  CDoc *doc,*old=Fs->put_doc;
  Bool typed;
  for(i=0;i<6;i++) {
    doc=DocNew;
    name=MStrPrint("%c:/T.TXT",drive);
    if(i==2){Free(name);name=MStrPrint("%c:/M.DD",drive);}
    if(i>=4){Free(name);name=MStrPrint("%c:/G.GR",drive);}
    if(i==0 || i==4)typed=DocType(doc,name,0);
    if(i==1)typed=DocType(doc,name,2);
    if(i==2)typed=DocType(doc,name);
    if(i==3 || i==5) {
      Fs->put_doc=doc;
      if(i==3)typed=Type(name);else typed=Type(name,2);
      Fs->put_doc=old;
    }
    saved=DocSave(doc,&size);target=MStrPrint("%c:/type%d.DD",drive,i);
    if(typed && FileWrite(target,saved,size)>0)mask|=1<<i;
    Free(saved);Free(target);Free(name);DocDel(doc);
  }
  doc=DocNew;
  if(!DocType(doc,"unknown.XYZ"))mask|=64;
  signature=doc->doc_signature;doc->doc_signature=0;
  if(!DocType(doc,"T.TXT"))mask|=128;
  doc->doc_signature=signature;
  Fs->put_doc=NULL;
  if(!DocType(,"T.TXT"))mask|=256;
  Fs->put_doc=old;
  if(DocPut==old)mask|=512;
  DocDel(doc);return mask;
}
U0 DTWarm()
{
  I64 col=text.raw_col,flags=text.raw_flags;
  Bool raw=Raw(TRUE);
  RawPutChar(32);Raw(raw);text.raw_col=col;text.raw_flags=flags;
}
I64 DTRaw(I64 drive,I64 mode)
{
  I64 col=text.raw_col,flags=text.raw_flags,i;
  U8 *output=CAlloc(192048),*cache=text.raw_scrn_image,*name,read_plane;
  I64 *meta=output;
  CDoc *doc=DocNew;
  Bool raw=Raw(TRUE),suspended=Suspend(sys_winmgr_task),ok=TRUE;
  text.raw_scrn_image=output+48;text.raw_col=0;text.raw_flags=0;
  OutU8(0x3C4,2);OutU8(0x3C5,15);MemSet(text.vga_alias,0,38400);
  if(!mode) {DocPrint(doc,"one\nlast");DocDump(doc);}
  else {
    name=MStrPrint("%c:/T.TXT",drive);ok=DocType(doc,name,0);Free(name);
  }
  meta[0]=text.raw_col;meta[1]=text.raw_flags;meta[2]=text.cols;meta[3]=text.rows;
  meta[4]=IsRaw;meta[5]=ok;
  OutU8(0x3CE,4);read_plane=InU8(0x3CF);
  for(i=0;i<4;i++){OutU8(0x3CF,i);MemCpy(output+48+38400*(i+1),text.vga_alias,38400);}
  OutU8(0x3CF,read_plane);
  text.raw_scrn_image=cache;text.raw_col=col;text.raw_flags=flags;
  Raw(raw);Suspend(sys_winmgr_task,suspended);
  DocDel(doc);
  name=MStrPrint("%c:/raw-type%d.BIN",drive,mode);
  if(FileWrite(name,output,192048)<=0)ok=FALSE;
  Free(name);Free(output);return ok;
}
