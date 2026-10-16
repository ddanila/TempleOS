I64 DPRaw(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0,flags=text.raw_flags,col=text.raw_col;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;CDocEntry *last=put->head.last;
 Bool raw=Raw(TRUE),pending;
 text.raw_flags&=~(RWF_IN_DOLLAR|RWF_LAST_DOLLAR);
 if(mode==7)Print("%cFG,4",36);
 pending=(text.raw_flags&RWF_IN_DOLLAR)!=0;
 GetOutOfDollar;
 if(pending==(mode==7)&&!(text.raw_flags&RWF_IN_DOLLAR))m|=1;
 if(put->head.last==last)m|=2;
 if(IsRaw)m|=4;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
 text.raw_flags=flags;text.raw_col=col;Raw(raw);
 if(Fs->data_heap->used_u8s==before)m|=16;
 if(m!=31){U8*s=MStrPrint("RAW DIAG %d mask %d pending %d\n",mode,m,pending),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}
 return m;
}
I64 DPContract(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0,spaces=0,color=RED,fg=DOC_DFT;Bool blink=FALSE,raw=Raw(FALSE),style=FALSE;
 CDoc *old=DocPut,*display=DocDisplay,*border=DocBorder,*d=DocNew("Diagnostic.DD");
 CDocEntry *e;U8 *at,*scan,*line,*want,*label="WARNING:";
 Fs->put_doc=d;
 if(mode==2||mode==4){label="ERROR:";color=LTRED;}
 if(mode==1||mode>=4)Print("%cFG,4",36);
 if(mode<2){GetOutOfDollar;Print("X");want="X";}
 else if(mode==2||mode==4){PrintErr("value=%d %s",42,"ok");want="ERROR: value=42 ok";}
 else {PrintWarn("value=%d %s",42,"ok");want="WARNING: value=42 ok";}
 line=DocScanLine(d,d->head.next);
 if(!(d->flags&DOCF_IN_DOLLAR))m|=2;
 for(e=d->head.next;e!=d;e=e->next){
  if(e->type_u8==DOCT_FOREGROUND)fg=e->attr;
  if(e->type_u8==DOCT_BLINK)blink=e->attr!=0;
  if(e->tag&&((mode<2&&!StrCmp(e->tag,"X")&&(mode!=1||fg==RED))||
     (mode>=2&&StrFind(label,e->tag)&&
       fg==color&&blink)))style=TRUE;
 }
 at=NULL;if(line)at=StrFind(want,line);
 if(at){for(scan=line;scan<at;scan++)if(*scan==32)spaces++;
  if(!StrCmp(at,want)&&(mode<2&&at==line||mode>=2&&spaces==4))m|=1;}
 if(style&&(mode<2||fg==DOC_DFT&&!blink))m|=4;
 if(DocPut==d&&DocDisplay==display&&DocBorder==border)m|=8;
 if(m!=15){U8*s=MStrPrint("DIAG %d mask %d line %s\n",mode,m,line),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}
 Free(line);Fs->put_doc=old;DocDel(d);Raw(raw);
 if(Fs->data_heap->used_u8s==before)m|=16;
 return m;
}
I64 DPCheck(I64 mode){I64 m;if(mode<6)m=DPContract(mode);else m=DPRaw(mode);if(m!=31)throw('DiagPrnt',TRUE);return m;}
