U0 FmtLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool FmtText(CDoc *doc,U8 *expected,Bool suffix=FALSE)
{
  CDocEntry *e=doc->head.next;
  U8 text[256],*s;
  I64 n=0;
  while(e!=doc) {
    if(e->type_u8==DOCT_TEXT) {
      s=e->tag;while(*s && n<255)text[n++]=*s++;
    } else if(e->type_u8==DOCT_NEW_LINE && n<255)text[n++]='\n';
    e=e->next;
  }
  text[n]=0;
  if(suffix) {
    if(n<StrLen(expected))return FALSE;
    return !StrCmp(text+n-StrLen(expected),expected);
  }
  return !StrCmp(text,expected);
}
U0 FmtCheck()
{
  CDrv dv,*saved=blkdev.let_to_drv[25];
  CBlkDev bd;
  CDoc *saved_doc=DocPut,*doc=DocNew("Format.DD");
  U8 *home=DirCur,*copy,*data,*s;
  I64 v[16],size;
  Bool old_silent=IsSilent;
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.bd=&bd;
  dv.drv_offset=88;dv.size=128;dv.fs_type=FSt_REDSEA;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.first_drv_let='Z';
  bd.max_blk=215;bd.drv_offset=88;bd.blk_size=512;bd.init_root_dir_blks=2;
  bd.flags=BDF_INITIALIZED;bd.RAM_dsk=CAlloc(216*512);
  blkdev.let_to_drv[25]=&dv;Fs->put_doc=doc;Silent(FALSE);FlushMsgs;
  MemSet(bd.RAM_dsk,0xA5,216*512);copy=MAlloc(216*512);MemCpy(copy,bd.RAM_dsk,216*512);
  Msg(MSG_KEY_DOWN,'n',0x31);Fmt('Z');
  v[0]=!MemCmp(copy,bd.RAM_dsk,216*512);
  v[1]=FmtText(doc,"ARE YOU SURE (y or n)? NO\n");
  v[2]=Fs->cur_dv!=&dv && !IsSilent;DocRst(doc,TRUE);
  Msg(MSG_KEY_DOWN,'y',0x15);Fmt('Z');
  v[3]=FmtText(doc,"ARE YOU SURE (y or n)? YES\nUsing RedSea File System.\n");
  v[4]=CallExtStr("RedSeaValidate",'Z') && dv.fs_type==FSt_REDSEA;
  v[5]=Fs->cur_dv==&dv && !StrCmp(Fs->cur_dir,"/") && !IsSilent;
  v[6]=bd.RAM_dsk[215*512]==0xA5;
  v[7]=!MemCmp(copy,bd.RAM_dsk,88*512);
  v[8]=DirMk("Z:/Sub") && FileWrite("Z:/Sub/Test.DATA","format-data",11)!=0;
  data=FileRead("Z:/Sub/Test.DATA",&size);
  v[9]=data && size==11 && !MemCmp(data,"format-data",11);Free(data);
  DocRst(doc,TRUE);MemCpy(copy,bd.RAM_dsk,216*512);
  Fmt('Z',TRUE,FALSE,12345);
  v[10]=!MemCmp(copy,bd.RAM_dsk,216*512);
  v[11]=FmtText(doc,"ERROR: File System Not Supported\n",TRUE);DocRst(doc,TRUE);
  Silent(TRUE);Fmt('Z',FALSE,FALSE,FSt_REDSEA);
  v[12]=CallExtStr("RedSeaValidate",'Z') && IsSilent;
  v[13]=bd.RAM_dsk[215*512]==0;
  v[14]=!FileFind("Z:/Sub/Test.DATA",,FUF_JUST_FILES);
  FileWrite("Z:/After.DATA","after",5);
  data=FileRead("Z:/After.DATA",&size);
  v[15]=data && size==5 && !MemCmp(data,"after",5);Free(data);
  Cd(home);Silent(old_silent);FlushMsgs;
  DskCacheInvalidate(&dv);CallExtStr("RedSeaFreeFreeLst",&dv);
  Free(dv.cur_fat_blk);Free(bd.RAM_dsk);Free(copy);Free(home);
  blkdev.let_to_drv[25]=saved;Fs->put_doc=saved_doc;DocDel(doc);
  s=MStrPrint("EXPORT format.bin %X %X\n",v,sizeof(v));FmtLog(s);Free(s);
  FmtLog("FORMAT DONE\n");Sleep(1000);
}
