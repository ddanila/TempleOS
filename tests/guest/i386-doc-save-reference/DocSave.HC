I64 DSPlain(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,type,flags,attr;
  CDoc *put=DocPut,*d=DocNew("PlainEntry.DD");
  CDocEntry *e;
  U8 *want,*got,*tag;
  Bool locked=mode==6;
  U32 value=7;
  switch(mode) {
    case 0:e=DocPrint(d,"$$FG,4$$");want=StrNew("FG,4");break;
    case 1:e=DocPrint(d,"$$FG,4$$");d->flags|=DOCF_COLOR_NAMES;want=StrNew("RED");break;
    case 2:e=DocPrint(d,"$$BT,\"Go\",LE=11,RE=-3$$");want=StrNew("BT,\"Go\",LE=11,RE=-3");break;
    case 3:
      e=DocPrint(d,"$$TX,\"Tag\"$$");Free(e->tag);e->tag=MStrPrint("a%cb%c%c",34,92,36);
      want=MStrPrint("TX,%ca%c%cb%c%c%cd%c",34,92,34,92,92,92,34);break;
    case 4:e=DocPrint(d,"$$LK,\"Link\",A=\"FI:C:/Test.HC\"$$");want=StrNew("LK,\"Link\",A=\"FI:C:/Test.HC\"");break;
    case 5:e=DocPrint(d,"$$MA,\"Run\",LM=\"6*7;\"$$");want=StrNew("MA,\"Run\",LM=\"6*7;\"");break;
    case 6:
      e=DocPrint(d,"$$TX,\"Flag\"$$");e->de_flags|=DOCEF_SKIP_IN_FORM|DOCEF_USER_DATA;e->user_data=0x1234;
      want=StrNew("TX+SIF,\"Flag\",U=0x1234");break;
    case 7:
      e=DocPrint(d,"$$TX,\"7\"$$");e->type=DOCT_DATA|doldoc.dft_type_flags[DOCT_DATA];
      e->de_flags=doldoc.dft_de_flags[DOCT_DATA]|DOCEF_TAG|DOCEF_LEN|DOCEF_AUX_STR|DOCEF_RAW_TYPE;
      e->de_flags&=~DOCEF_REMALLOC_DATA;e->aux_str=StrNew("%d");e->len=8;e->raw_type=RT_U32;e->data=&value;
      want=StrNew("DA,LEN=8,A=\"%d\",RT=U32");break;
  }
  if(locked)DocLock(d);
  type=e->type;flags=e->de_flags;attr=e->attr;tag=e->tag;
  got=Doc2PlainText(d,e);
  if(got&&!StrCmp(got,want))m|=1;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==locked&&(!locked||d->owning_task==Fs))m|=2;
  if(e->type==type&&e->de_flags==flags&&e->attr==attr&&e->tag==tag)m|=4;
  if(DocPut==put)m|=8;
  //Failure diagnostics avoid guessing the original canonical spelling.
  if(!(m&1)){U8 *s=MStrPrint("OBS serialize %d %s\n",mode,got);U8*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}
  Free(got);Free(want);DocUnlock(d);DocDel(d);
  if(Fs->data_heap->used_u8s==before)m|=16;
  return m;
}
U8 *DSBin(I64 number,I64 uses,I64 *size)
{
  U8 *text=MStrPrint("%cSP,\"dot\",BI=%d%c",36,number,36),*raw;
  CDocBin *header=CAlloc(sizeof(CDocBin));
  I64 n=StrLen(text)+1,h=offset(CDocBin.end)-offset(CDocBin.start);
  *size=n+h+5;raw=CAlloc(*size);MemCpy(raw,text,n);
  header->num=number;header->size=5;header->use_cnt=uses;MemCpy(raw+n,&header->start,h);
  raw[n+h]=1;raw[n+h+1]=2;raw[n+h+2]=0;raw[n+h+3]=255;raw[n+h+4]=42;
  Free(header);Free(text);return raw;
}
I64 DSSave(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,size,wanted_size=0,i,raw_size,want_ch;
  CDoc *put=DocPut,*d=DocNew("Serialize.DD"),*copy=DocNew("Loaded.DD");
  U8 *saved,*wanted,*line,*raw=NULL,*round_line="AB";
  Bool same=TRUE,locked=mode==7;
  CDocEntry *field;U32 value=7;
  if(mode!=5)d->flags|=DOCF_NO_CURSOR;
  switch(mode) {
    case 0:case 7:DocPrint(d,"AB\n");wanted=StrNew("AB\n");break;
    case 8:d->flags|=DOCF_CARRIAGE_RETURN;DocPrint(d,"AB\n");wanted=StrNew("AB\r\n");break;
    case 9:
      DocPrint(d,"Head\n");field=DocPrint(d,"$$TX,\"7\"$$");
      field->type=DOCT_DATA|doldoc.dft_type_flags[DOCT_DATA];
      field->de_flags=doldoc.dft_de_flags[DOCT_DATA]|DOCEF_TAG|DOCEF_LEN|DOCEF_AUX_STR|DOCEF_RAW_TYPE|DOCEF_DEREF_DATA;
      field->de_flags&=~DOCEF_REMALLOC_DATA;field->aux_str=StrNew("%d");field->len=8;field->raw_type=RT_U32;field->data=&value;
      wanted=StrNew("Head\n");round_line="Head";break;
    case 1:case 2:
      d->flags|=DOCF_PLAIN_TEXT;if(mode==2)d->flags|=DOCF_DBL_DOLLARS;
      DocPrint(d,"cash%cRED%c",36,36);
      if(mode==1)wanted=MStrPrint("cash%cRED%c",36,36);
      else wanted=MStrPrint("cash%c%cRED%c%c",36,36,36,36);
      round_line=wanted;break;
    case 3:
      DocPrint(d,"$$MU,\"Go\",LE=11,RE=12$$");wanted=MStrPrint("%cMU,\"Go\",LE=11,RE=12%c",36,36);round_line="Go";break;
    case 4:
      d->flags|=DOCF_COLOR_NAMES;DocPrint(d,"$$FG,4$$AB");wanted=MStrPrint("%cRED%cAB",36,36);break;
    case 5:DocPrint(d,"ABCD");wanted=MStrPrint("AB%cCD",CH_CURSOR);round_line="ABCD";break;
    case 6:raw=DSBin(7,0,&raw_size);DocLoad(d,raw,raw_size);Free(raw);raw=NULL;wanted=DSBin(1,1,&wanted_size);round_line="dot";break;
  }
  if(!wanted_size)wanted_size=StrLen(wanted);
  DocTop(d);if(mode==5){EdCursorRight(d);EdCursorRight(d);}
  want_ch=EdCurU8(d);if(locked)DocLock(d);
  saved=DocSave(d,&size);
  if(saved&&size==wanted_size)m|=1;
  if(saved&&size==wanted_size){for(i=0;i<size;i++)if(saved[i]!=wanted[i])same=FALSE;if(mode!=6&&saved[size])same=FALSE;}
  else same=FALSE;
  if(same)m|=2;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==locked&&(!locked||d->owning_task==Fs)&&DocPut==put)m|=4;
  if(saved){
    copy->flags|=d->flags&(DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS);
    DocLoad(copy,saved,size);line=DocScanLine(copy,copy->head.next);
    if(line&&!StrCmp(line,round_line))m|=8;
    Free(line);
  }
  if(EdCurU8(d)==want_ch)m|=16;
  if((m&3)!=3){U8*s=MStrPrint("OBS save %d size %d wanted %d\n",mode,size,wanted_size),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}
  Free(saved);Free(wanted);DocUnlock(d);DocDel(d);DocDel(copy);
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
