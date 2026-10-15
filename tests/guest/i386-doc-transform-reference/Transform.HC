Bool TTLine(CDoc*d,U8*want){U8*s=DocScanLine(d,d->head.next);Bool ok=s&&!StrCmp(s,want);U8*p;if(!ok){p="TRANSFORM LINE ";while(*p)OutU8(0xE9,*p++);p=s;if(p)while(*p)OutU8(0xE9,*p++);OutU8(0xE9,10);}Free(s);return ok;}
Bool TTBytes(U8*a,U8*b,I64 n){I64 i;for(i=0;i<n;i++)if(a[i]!=b[i])return FALSE;return TRUE;}
I64 TTMenus(CDoc*d){I64 n=0;CDocEntry*e;for(e=d->head.next;e!=d;e=e->next)if(e->type_u8==DOCT_MENU_VAL&&e->left_exp==7)n++;return n;}
Bool TTDollar(CDoc*d){CDocEntry*e;I64 i;for(e=d->head.next;e!=d;e=e->next)if(e->tag)for(i=0;e->tag[i];i++)if(e->tag[i]==36)return TRUE;return FALSE;}
I64 TTCollapse(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,fa,fb,fc;
  CDoc *old=Fs->put_doc,*display=DocDisplay,*d=DocNew("Tree.DD");
  CDocEntry*a=DocPrint(d,"$$TR,\"A\"$$"),*b,*c;
  DocPrint(d,"\n");b=DocPrint(d,"$$TR,\"B\"$$");DocPrint(d,"\n");
  c=DocPrint(d,"$$BT,\"Control\"$$");DocTop(d);
  c->de_flags|=DOCEF_CHECKED_COLLAPSED;fa=a->de_flags;fb=b->de_flags;fc=c->de_flags;
  if(mode==1)Fs->put_doc=d;
  if(mode==2)DocLock(d);
  if(mode==1)DocCollapse(FALSE);else DocCollapse(FALSE,d);
  if(!(a->de_flags&DOCEF_CHECKED_COLLAPSED)&&!(b->de_flags&DOCEF_CHECKED_COLLAPSED))m|=1;
  DocCollapse(TRUE,d);
  if(a->de_flags&DOCEF_CHECKED_COLLAPSED&&b->de_flags&DOCEF_CHECKED_COLLAPSED)m|=2;
  if(!((a->de_flags^fa)&~DOCEF_CHECKED_COLLAPSED)&&!((b->de_flags^fb)&~DOCEF_CHECKED_COLLAPSED)&&c->de_flags==fc&&a->type_u8==DOCT_TREE&&b->type_u8==DOCT_TREE)m|=4;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode==2))m|=8;
  if(Fs->put_doc==old&&mode!=1||mode==1&&Fs->put_doc==d)if(DocDisplay==display)m|=16;
  Fs->put_doc=old;DocUnlock(d);DocDel(d);
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
I64 TTFlags(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,flag=DOCF_PLAIN_TEXT,size;
  CDoc *old=DocPut,*display=DocDisplay,*d=DocNew("Flags.DD");CDocUndo*u;U8*copy,*body,*want=MStrPrint("A%cMU,\"Go\",LE=7%cB",36,36);
  if(mode)flag=DOCF_PLAIN_TEXT_TABS;
  DocPrint(d,"A$$MU,\"Go\",LE=7$$B");DocTop(d);d->flags|=DOCF_NO_CURSOR|DOCF_ALLOW_UNDO;
  DocCaptureUndo(d,TRUE);u=d->undo_head.last;size=u->size;body=u->body;copy=MAllocIdent(body);
  if(mode)DocLock(d);
  DocFlagsToggle(d,flag);
  if(d->flags&flag&&!TTMenus(d)&&TTLine(d,want))m|=1;
  DocFlagsToggle(d,flag);
  if(!(d->flags&flag)&&d->flags&DOCF_NO_CURSOR&&TTMenus(d)==1&&TTLine(d,"AGoB"))m|=2;
  if(d->undo_cnt==1&&d->undo_head.next==u&&d->undo_head.last==u&&u->next==&d->undo_head&&u->last==&d->undo_head&&u->body==body&&u->size==size&&TTBytes(copy,body,size))m|=4;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode!=0))m|=8;
  if(DocPut==old&&DocDisplay==display)m|=16;
  Free(want);Free(copy);DocUnlock(d);DocDel(d);
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
I64 TTEntry(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,flags;Bool round_ok=TRUE;
  CDoc*old=DocPut,*display=DocDisplay,*d=DocNew("Entry.DD");U8*raw=MStrPrint("%cMU,\"Go\",LE=7%c",36,36),*literal=MStrPrint("%cMU,%c%cGo%c%c,LE=7%c",36,92,34,92,34,36);
  if(mode==0||mode==5)DocPrint(d,"$$MU,\"Go\",LE=7$$");
  else if(mode==1||mode==2){
    d->flags|=DOCF_PLAIN_TEXT;
    DocLoad(d,raw,StrLen(raw));if(mode==1)d->flags&=~DOCF_PLAIN_TEXT;
  }else DocPrint(d,"AB");
  DocTop(d);if(mode==1)d->cur_col=3;
  if(mode==3)d->cur_entry=d;
  flags=d->flags&(DOCF_COLOR_NAMES|DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS|DOCF_NO_CURSOR);
  DocEntryToggle(d);
  if(mode==5){round_ok=TTLine(d,literal);DocTop(d);d->cur_col=3;DocEntryToggle(d);}
  if(mode==0&&!TTMenus(d)&&TTDollar(d)||(mode==1||mode==5)&&TTMenus(d)==1||2<=mode<=4&&!TTMenus(d))m|=1;
  if((d->flags&(DOCF_COLOR_NAMES|DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS|DOCF_NO_CURSOR))==flags)m|=2;
  if(round_ok&&(mode==0&&TTLine(d,literal)||mode==2&&TTLine(d,raw)||(mode==1||mode==5)&&TTLine(d,"Go")||3<=mode<=4&&TTLine(d,"AB")))m|=4;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=8;
  if(DocPut==old&&DocDisplay==display)m|=16;
  Free(literal);Free(raw);DocDel(d);if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
I64 TTCheck(I64 group,I64 mode){I64 m;if(!group)m=TTCollapse(mode);else if(group==1)m=TTFlags(mode);else m=TTEntry(mode);if(m!=63)throw('DocTog',TRUE);return m;}
