I64 ck_caller[19],ck_root[19];
Bool CKLine(CDoc *d,U8 *wanted)
{U8 *s=DocScanLine(d,d->head.next);Bool r;if(s)r=!StrCmp(s,wanted);else r=!*wanted;Free(s);return r;}
I64 ck_callbacks;
Bool CKConsume(CDoc *d,U8 *data,I64 ch,I64 sc){ck_callbacks++;return TRUE;}
I64 CKCase(I64 mode)
{
  I64 before,root_before,m=0,ch=CH_CTRLC,sc=SCF_CTRL,flags=GetRFlags;
  CDoc *d,*t,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *e;
  U8 *source="AB",*target="xy",*clip="Seed",*desc="";
  Bool locked=mode==16,selected=TRUE,cut=FALSE;
  //Synchronous single-CPU resource oracle excludes unrelated root-task work.
  SetRFlags(flags&~512);
  ClipDel;before=Fs->data_heap->used_u8s;root_before=sys_clip_doc->mem_task->data_heap->used_u8s;
  d=DocNew("KeysSource.DD");t=DocNew("KeysTarget.DD");
  DocPrint(d,"AB");DocPrint(t,"xy");DocPrint(sys_clip_doc,"Seed");
  DocTop(d);DocTop(t);EdCursorRight(t);e=d->head.next;e->type|=DOCET_SEL;
  d->flags|=DOCF_DONT_SWAP_OUT;t->flags|=DOCF_DONT_SWAP_OUT;
  ck_callbacks=0;
  switch(mode) {
    case 1:ch=CH_CTRLX;cut=TRUE;break;
    case 2:ch=0;sc=SC_INS|SCF_CTRL;break;
    case 3:ch=0;sc=SC_DELETE|SCF_SHIFT;cut=TRUE;break;
    case 4:sc|=SCF_SHIFT;break;
    case 5:ch=CH_CTRLV;sc|=SCF_SHIFT;break;
    case 6:ch=CH_CTRLX;sc|=SCF_SHIFT;break;
    case 7:ch=0;sc=SC_INS|SCF_SHIFT|SCF_CTRL;break;
    case 8:ch=0;sc=SC_DELETE|SCF_SHIFT|SCF_CTRL;break;
    case 9:sc|=SCF_ALT;break;
    case 10:desc="Edit/Copy to Clip";break;
    case 11:ch=CH_CTRLV;desc="Edit/Paste Clip";break;
    case 12:ch=CH_CTRLX;desc="Edit/Cut To Clip";break;
    case 13:ch=0;sc=SC_INS|SCF_CTRL;desc="Edit/Copy to Clip";break;
    case 14:ch=0;sc=SC_INS|SCF_SHIFT;desc="Edit/Paste Clip";break;
    case 15:ch=0;sc=SC_DELETE|SCF_SHIFT;desc="Edit/Cut To Clip";break;
    case 17:d->user_put_key=&CKConsume;break;
    case 18:e->type&=~DOCET_SEL;selected=FALSE;clip="";break;
  }
  if(10<=mode<=15)sc|=SCF_KEY_DESC;
  if(locked){DocLock(d);DocLock(t);DocLock(sys_clip_doc);}
  DocPutKey(d,ch,sc);
  if(mode<4 || mode==16) {
    clip="AB";target="xABy";selected=FALSE;
    if(cut)source="";
    if(mode==2 || mode==3)DocPutKey(t,0,SC_INS|SCF_SHIFT);
    else DocPutKey(t,CH_CTRLV,SCF_CTRL);
  }
  if(CKLine(d,source))m|=1;
  if(CKLine(t,target))m|=2;
  if(CKLine(sys_clip_doc,clip))m|=4;
  if(cut || Bt(&e->type,DOCEt_SEL)==selected)m|=8;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==locked && Bt(&t->locked_flags,DOClf_LOCKED)==locked &&
      Bt(&sys_clip_doc->locked_flags,DOClf_LOCKED)==locked)m|=16;
  if((!*desc || !StrCmp(keydev.desc,desc)) && ck_callbacks==(mode==17))m|=32;
  if(DocPut==put && DocDisplay==display && DocBorder==border && !(GetRFlags&512))m|=64;
  DocUnlock(d);DocUnlock(t);DocUnlock(sys_clip_doc);DocDel(d);DocDel(t);ClipDel;
  ck_caller[mode]=Fs->data_heap->used_u8s-before;
  ck_root[mode]=sys_clip_doc->mem_task->data_heap->used_u8s-root_before;
  if(!ck_caller[mode] && !ck_root[mode])m|=128;
  SetRFlags(flags);return m;
}
U0 CKLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 CKCheck()
{
  I64 rows[19],i;U8 *s;
  CKCase(0); //Warm lazy document layout state before exact resource checks.
  for(i=0;i<19;i++)rows[i]=CKCase(i);
  s=MStrPrint("EXPORT clipboard-key-rows.bin %X %X\n",rows,sizeof(rows));CKLog(s);Free(s);
  s=MStrPrint("EXPORT clipboard-caller.bin %X %X\n",ck_caller,sizeof(ck_caller));CKLog(s);Free(s);
  s=MStrPrint("EXPORT clipboard-root.bin %X %X\n",ck_root,sizeof(ck_root));CKLog(s);Free(s);
  CKLog("CLIPBOARD KEYS DONE\n");Sleep(1000);
}
