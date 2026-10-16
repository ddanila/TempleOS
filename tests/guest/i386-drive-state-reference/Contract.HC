U8 ds_base[STR_LEN];
Bool DSSetup(U8 drive)
{
 U8*root=MStrPrint("%c:/",drive);Bool ok=Cd(root);Free(root);
 DirMk("Probe");Cd("Probe");DirMk("DriveState");ok=ok&&Cd("DriveState");
 DirMk("A");StrCpy(ds_base,Fs->cur_dir);return ok;
}
I64 DSContract(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0;
 CDrv*drive=Fs->cur_dv;CBlkDev*bd=drive->bd;
 CDoc*put=DocPut,*display=DocDisplay,*border=DocBorder;
 U8 letter=Drv2Let(drive);U8*want=ds_base;
 Bool operation=FALSE,caught=FALSE;CDirContext*context;I64 flags;
 if(mode==0)operation=Let2Drv()==drive&&Let2Drv(letter-'A'+'a')==drive;
 else if(mode==1){operation=Drv(0);want="/";}
 else if(mode==2){operation=Drv(letter-'A'+'a');want="/";}
 else if(mode==3){operation=Drv(letter);want="/";}
 else if(mode==4)operation=Let2Drv('?',FALSE)==NULL;
 else if(mode==5){
  try{Drv('?');}catch{caught=Fs->except_ch=='Drv';Fs->catch_except=TRUE;}
  operation=caught;
 }else if(mode==6){
  context=DirContextNew("A/*.HC");
  operation=context&&context->old_dv==drive&&!StrCmp(context->old_dir,ds_base);
  flags=bd->flags;bd->flags|=BDF_INIT_IN_PROGRESS;
  DirContextDel(context);bd->flags=flags;want="/";
 }else if(mode==7)operation=DrvChk(NULL,FALSE)==NULL&&DrvChk(drive)==drive;
 else if(mode==8)operation=Let2Drv(':')==Let2Drv(Let2Let(':'))&&Let2Drv('~')==Let2Drv(Let2Let('~'));
 if(operation)m|=1;
 if(Fs->cur_dv==drive&&!StrCmp(Fs->cur_dir,want))m|=2;
 if(drive->bd==bd&&bd&&bd->bd_signature==BD_SIGNATURE_VAL&&
    bd->type==Let2BlkDevType(letter)&&bd->flags&BDF_INITIALIZED&&
    !(bd->flags&BDF_INIT_IN_PROGRESS))m|=4;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
 //Restore only after observing the drive reset/initialization branch.
 Cd(ds_base);
 if(Fs->data_heap->used_u8s==before)m|=16;
 return m;
}
I64 DSCheck(I64 mode){I64 m=DSContract(mode);if(m!=31)throw('DrvState',TRUE);return m;}
