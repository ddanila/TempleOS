U8 *DLBin(I64 *size)
{
  U8 *text=MStrPrint("%cSP,\"dot\",BI=7%c",36,36),*raw;
  CDocBin *header=CAlloc(sizeof(CDocBin));
  I64 n=StrLen(text)+1,h=offset(CDocBin.end)-offset(CDocBin.start);
  *size=n+h+5;raw=CAlloc(*size);MemCpy(raw,text,n);
  header->num=7;header->size=5;MemCpy(raw+n,&header->start,h);
  raw[n+h]=1;raw[n+h+1]=2;raw[n+h+2]=0;raw[n+h+3]=255;raw[n+h+4]=42;
  Free(header);Free(text);return raw;
}
I64 DLContract(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,size=0,i,want='A';
  CDoc *put=DocPut,*d=DocNew("Load.DD");
  CDocEntry *e;
  CDocBin *b;
  U8 *raw=NULL,*copy=NULL,*line,*expected="ABC";
  Bool locked=mode==2,same=TRUE,binary=TRUE;
  if(mode==1){DocPrint(d,"xy");DocBottom(d);raw=StrNew("AB\n");expected="xyAB";want='x';}
  else if(mode==3){DocPrint(d,"Keep");expected="Keep";want='K';}
  else if(mode==4){d->flags|=DOCF_PLAIN_TEXT;raw=MStrPrint("%cRED%cAB\t\n",36,36);expected=MStrPrint("%cRED%cAB\t",36,36);want=36;}
  else if(mode==5){raw=MStrPrint("AB%cCD\n",CH_CURSOR);expected="ABCD";want='C';}
  else if(mode==6){raw=DLBin(&size);expected="dot";want=-1;}
  else raw=StrNew("ABC\n");
  if(raw&&!size)size=StrLen(raw)+1;
  if(raw)copy=MAllocIdent(raw);
  d->find_replace->filter_lines=17;
  if(locked)DocLock(d);
  DocLoad(d,raw,size);
  if(mode==6){
    e=d->head.next;b=d->bin_head.next;
    binary=e!=d&&e->type_u8==DOCT_SPRITE&&b!=&d->bin_head&&b->next==&d->bin_head&&
      e->bin_data==b&&e->bin_num==1&&b->num==1&&b->use_cnt==1&&b->size==5&&d->cur_bin_num==2;
    if(binary)binary=b->data[0]==1&&b->data[1]==2&&!b->data[2]&&b->data[3]==255&&b->data[4]==42;
  }
  line=DocScanLine(d,d->head.next);
  if(line&&!StrCmp(line,expected)&&binary)m|=1;
  Free(line);
  if(EdCurU8(d)==want)m|=2;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==locked&&(!locked||d->owning_task==Fs))m|=4;
  if(!d->find_replace->filter_lines&&DocPut==put)m|=8;
  for(i=0;i<size;i++)if(raw[i]!=copy[i])same=FALSE;
  if(same)m|=16;
  DocUnlock(d);DocDel(d);Free(raw);Free(copy);if(mode==4)Free(expected);
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
