I64 DLContract(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0,flags;
 CDrv*drive=Fs->cur_dv;CBlkDev*device=drive->bd,bad;
 CDoc*put=DocPut,*display=DocDisplay,*border=DocBorder;
 U8*directory=Fs->cur_dir;U8 letter=Drv2Let(drive);Bool ok=FALSE,caught=FALSE;
 if(mode==0)ok=Let2Drv()==drive&&Let2BlkDev()==device&&BlkDevChk(device)==device;
 else if(mode==1)ok=Let2Drv(letter-'A'+'a')==drive&&Let2BlkDev(letter)==device;
 else if(mode==2)ok=Let2Drv(':')==Let2Drv(Let2Let(':'))&&Let2Drv('~')==Let2Drv(Let2Let('~'));
 else if(mode==3)ok=Let2Drv('?',FALSE)==NULL&&Let2BlkDev('?',FALSE)==NULL;
 else if(mode==4){try{Let2Drv('?');}catch{caught=Fs->except_ch=='Drv';Fs->catch_except=TRUE;}ok=caught;}
 else if(mode==5)ok=BlkDevChk(NULL,FALSE)==NULL;
 else if(mode==6){MemCpy(&bad,device,sizeof(CBlkDev));bad.bd_signature=0;ok=BlkDevChk(&bad,FALSE)==NULL;}
 else if(mode==7){MemCpy(&bad,device,sizeof(CBlkDev));bad.type=BDT_NULL;ok=BlkDevChk(&bad,FALSE)==NULL;bad.type=BDT_TYPES_NUM;ok=ok&&BlkDevChk(&bad,FALSE)==NULL;}
 else if(mode==8){try{BlkDevChk(NULL);}catch{caught=Fs->except_ch=='BlkDev';Fs->catch_except=TRUE;}ok=caught;}
 else if(mode==9){flags=device->flags;device->flags&=~BDF_READ_ONLY;ok=DrvIsWritable()==device;device->flags|=BDF_READ_ONLY;ok=ok&&DrvIsWritable()==NULL;device->flags=flags;}
 else if(mode==10){flags=device->flags;device->flags|=BDF_READ_ONLY;try{DrvIsWritable(0,TRUE);}catch{caught=Fs->except_ch=='Drv';Fs->catch_except=TRUE;}device->flags=flags;ok=caught;}
 else if(mode==11){drive->dv_signature=0;ok=Let2Drv(0,FALSE)==NULL&&Let2Drv(letter,FALSE)==NULL;drive->dv_signature=DRV_SIGNATURE_VAL;}
 if(ok)m|=1;
 if(Fs->cur_dv==drive&&Fs->cur_dir==directory)m|=2;
 if(drive->bd==device&&device->bd_signature==BD_SIGNATURE_VAL)m|=4;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
 if(Fs->data_heap->used_u8s==before)m|=16;
 return m;
}
I64 DLCheck(I64 mode){I64 m=DLContract(mode);if(m!=31)throw('DrvLook',TRUE);return m;}
