U0 SKLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 sk_calls;
Bool SKCallback(CDoc *doc,I64 data,I64 ch,I64 sc)
{sk_calls++;return data;}
Bool SKBytes(U8 *name,U8 *wanted)
{
  I64 size;U8 *s;Bool okay;
  if(!wanted)return !FileFind(name);
  s=FileRead(name,&size);okay=s && size==StrLen(wanted) && !MemCmp(s,wanted,size);Free(s);return okay;
}
Bool SKSaved(I64 i){return i==6 || i==7 || i==9 || i==10 || i==11;}
U0 SKCheck(U8 *root)
{
  I64 i,sc,masks[14],col,signature;Bool locked,want_auto;
  CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;CDocEntry *entry;
  U8 *name,*desc,*wanted,*line,*s,*cwd=DirCur,*now;
  if(IsDir(root))throw('Exists',TRUE);DirMk(root);
  for(i=0;i<14;i++) {
    name=MStrPrint("%s/Case%02d.TXT",root,i);
    if(i!=6)FileWrite(name,"unchanged\n",10);
    d=DocNew(name);d->flags|=DOCF_NO_CURSOR|DOCF_DONT_SWAP_OUT;
    DocPrint(d,"Keep\n");DocTop(d);entry=d->cur_entry;col=d->cur_col;
    sc=SCF_CTRL;desc="unset";want_auto=FALSE;locked=i==7 || i==12;
    if(i==0 || i==1 || i==12) {sc|=SCF_KEY_DESC;desc="Edit/Save";}
    if(i==1 || i==3 || i==4 || i==5)sc|=SCF_SHIFT;
    if(i==1)desc="Edit/Toggle AutoSave";
    if(i==2 || i==3)sc|=SCF_ALT;
    if(i==4)want_auto=TRUE;
    if(i==5)d->flags|=DOCF_AUTO_SAVE;
    if(i==8 || i==9) {d->user_put_key=&SKCallback;d->user_put_data=i==8;}
    if(i==10)Fs->put_doc=d;
    if(i==11)sc=0;
    if(locked)DocLock(d);
    signature=d->doc_signature;if(i==13)d->doc_signature=0;
    sk_calls=0;StrCpy(keydev.desc,"unset");DocPutKey(d,CH_CTRLS,sc);
    if(i==10) {
      //Exercise null resolution separately after the first save.
      FileWrite(name,"unchanged\n",10);DocPutKey(NULL,CH_CTRLS,sc);Fs->put_doc=put;
    }
    d->doc_signature=signature;masks[i]=0;
    if(!StrCmp(keydev.desc,desc))masks[i]|=1;
    if(Bt(&d->flags,DOCf_AUTO_SAVE)==want_auto)masks[i]|=2;
    line=DocScanLine(d,d->head.next);
    if(line && !StrCmp(line,"Keep") && d->cur_entry==entry && d->cur_col==col)masks[i]|=4;
    Free(line);
    if(Bt(&d->locked_flags,DOClf_LOCKED)==locked)masks[i]|=8;
    if(DocPut==put && DocDisplay==display && DocBorder==border)masks[i]|=16;
    wanted="unchanged\n";if(SKSaved(i))wanted="Keep\n";
    if(SKBytes(name,wanted))masks[i]|=32;
    if(sk_calls==(i==8 || i==9))masks[i]|=64;
    now=DirCur;if(!StrCmp(now,cwd))masks[i]|=128;Free(now);
    if(locked)DocUnlock(d);DocDel(d);Free(name);
  }
  Free(cwd);
  s=MStrPrint("EXPORT save-key-masks.bin %X %X\n",masks,sizeof(masks));SKLog(s);Free(s);
  SKLog("DOC SAVE KEYS DONE\n");Sleep(1000);
}
U0 SKReopen(U8 *root)
{
  I64 i,rows[14];U8 *name,*wanted,*s;
  for(i=0;i<14;i++) {
    name=MStrPrint("%s/Case%02d.TXT",root,i);wanted="unchanged\n";
    if(SKSaved(i))wanted="Keep\n";
    rows[i]=SKBytes(name,wanted);Free(name);
  }
  s=MStrPrint("EXPORT save-key-reopen.bin %X %X\n",rows,sizeof(rows));SKLog(s);Free(s);
  SKLog("DOC SAVE KEYS REOPEN DONE\n");Sleep(1000);
}
