U0 DRFail(I64 stage,I64 observed,I64 expected)
{
  U8*s=MStrPrint("FAIL read fixture stage %d observed %d expected %d\n",stage,observed,expected),*p=s;
  while(*p)OutU8(0xE9,*p++);Free(s);throw('ReadIO',TRUE);
}
U8 *DRBin(I64 *size)
{
  U8 *text=MStrPrint("%cSP,\"dot\",BI=7%c",36,36),*raw;
  CDocBin *header=CAlloc(sizeof(CDocBin));
  I64 n=StrLen(text)+1,h=offset(CDocBin.end)-offset(CDocBin.start);
  *size=n+h+5;raw=CAlloc(*size);MemCpy(raw,text,n);
  header->num=7;header->size=5;MemCpy(raw+n,&header->start,h);
  raw[n+h]=1;raw[n+h+1]=2;raw[n+h+2]=0;raw[n+h+3]=255;raw[n+h+4]=42;
  Free(header);Free(text);return raw;
}
I64 DRContract(U8 *path,I64 mode,Bool setup=TRUE)
{
  U8 *raw,*expected,*warm,*absolute,*old_dir=StrNew(Fs->cur_dir),*line,*after;
  I64 size=0,flags=0,attr,n,before,m=0,i,newlines=0;
  CDoc *put=DocPut,*d;
  CDocEntry *e;
  CDocBin *b;U32 *number;
  Bool shape=TRUE,same=TRUE;
  switch(mode) {
    case 0:raw=StrNew("AB\n");expected=StrNew("AB");break;
    case 1:raw=MStrPrint("%cMU,\"Go\",LE=11,RE=12%c",36,36);expected=StrNew("Go");break;
    case 2:raw=MStrPrint("%cRED%cAB",36,36);expected=StrNew("AB");break;
    case 3:raw=MStrPrint("%cLK,\"Link\",A=\"FI:Target.HC\"%c",36,36);expected=StrNew("Link");break;
    case 4:raw=StrNew("AB\r\n");expected=StrNew("AB");break;
    case 5:raw=MStrPrint("%cRED%cAB\t\n",36,36);expected=MStrPrint("%cRED%cAB\t",36,36);flags=DOCF_PLAIN_TEXT;break;
    case 6:raw=MStrPrint("AB%cCD\n",CH_CURSOR);expected=StrNew("ABCD");break;
    case 7:raw=DRBin(&size);expected=StrNew("dot");break;
    case 8:raw=StrNew("");expected=StrNew("");break;
    case 9:raw=CAlloc(18);raw[0]='A';number=raw+2;*number=7;size=18;expected=StrNew("A");break;
  }
  if(mode!=7&&mode!=9)size=StrLen(raw);
  if(setup){n=FileWrite(path,raw,size);if(size&&n<=0)DRFail(1,n,size);}
  warm=FileRead(path,&n,&attr);if(!warm||n!=size)DRFail(2,n,size);Free(warm);
  absolute=FileNameAbs(path);before=Fs->data_heap->used_u8s;
  d=DocRead(path,flags);
  if(d) {
    line=DocScanLine(d,d->head.next);if(line&&!StrCmp(line,expected))m|=1;Free(line);
    e=d->head.next;
    switch(mode) {
      case 0:case 4:
        while(e!=d){if(e->type_u8==DOCT_NEW_LINE)newlines++;e=e->next;}shape=newlines==1;break;
      case 1:shape=e!=d&&e->type_u8==DOCT_MENU_VAL&&e->left_exp==11&&e->right_exp==12;break;
      case 2:shape=e!=d&&e->type_u8==DOCT_FOREGROUND&&e->attr==RED;break;
      case 3:shape=e!=d&&e->type_u8==DOCT_LINK&&!StrCmp(e->aux_str,"FI:Target.HC");break;
      case 5:shape=d->flags&DOCF_PLAIN_TEXT&&e!=d&&e->type_u8==DOCT_TEXT;break;
      case 6:shape=EdCurU8(d)=='C';break;
      case 7:
        b=d->bin_head.next;shape=e!=d&&e->type_u8==DOCT_SPRITE&&b!=&d->bin_head&&b->next==&d->bin_head&&
          e->bin_data==b&&e->bin_num==1&&b->num==1&&b->use_cnt==1&&b->size==5;
        if(shape)shape=b->data[0]==1&&b->data[1]==2&&!b->data[2]&&b->data[3]==255&&b->data[4]==42;break;
      case 8:shape=EdCurU8(d)==-1;break;
      case 9:shape=d->bin_head.next==&d->bin_head&&d->cur_bin_num==1;break;
    }
    if(shape)m|=2;
    if((d->flags&DOCF_PLAIN_TEXT)==flags&&!Bt(&d->locked_flags,DOClf_LOCKED)&&!d->owning_task)m|=4;
    if(!StrCmp(d->filename.name,absolute)&&d->file_attr==attr&&DocPut==put&&!StrCmp(Fs->cur_dir,old_dir))m|=8;
    after=FileRead(path,&n);if(!after||n!=size)same=FALSE;
    else for(i=0;i<size;i++)if(after[i]!=raw[i])same=FALSE;
    Free(after);if(same)m|=16;
    DocDel(d);
  }
  if(Fs->data_heap->used_u8s==before)m|=32;
  Free(raw);Free(expected);Free(absolute);Free(old_dir);return m;
}
I64 DRCheck(U8 *path,I64 mode)
{
  I64 m=DRContract(path,mode);
  if(m!=63){U8*s=MStrPrint("OBS read %d mask %d\n",mode,m),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);throw('ReadCmp',TRUE);}
  return m;
}
I64 DRReject(U8 *path,I64 mode)
{
  U8 *raw,*warm;I64 size,n,before,m=0;
  CDoc *d,*put=DocPut;U32 *length;
  if(mode==0){size=9;raw=CAlloc(size);raw[0]='A';}
  else {size=18;raw=CAlloc(size);raw[0]='A';length=raw+2+offset(CDocBin.size)-offset(CDocBin.start);if(mode==2)*length=0xFFFFFFFF;else *length=100;}
  n=FileWrite(path,raw,size);if(size&&n<=0)DRFail(1,n,size);
  warm=FileRead(path,&n);Free(warm);before=Fs->data_heap->used_u8s;
  d=DocRead(path);if(!d)m|=1;else DocDel(d);
  if(DocPut==put)m|=2;if(Fs->data_heap->used_u8s==before)m|=4;
  Free(raw);return m;
}
