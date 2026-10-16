Bool BRHasDevice()
{
 I64 i;CBlkDev *bd=Fs->cur_dv->bd;
 while(bd->lock_fwding)bd=bd->lock_fwding;
 for(i=0;i<BLKDEVS_NUM;i++)if(BRBlockRecord(i)==bd)return TRUE;
 return FALSE;
}
I64 BRTable(I64 mode)
{
 CBlkDev saved[BLKDEVS_NUM],expected[BLKDEVS_NUM],*bd;
 CDrv *current=Fs->cur_dv;U8 *directory=Fs->cur_dir;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 CTask *other=adam_task;
 I64 i,j,before,m=0,shape=mode%4;
 Bool selected,exact=TRUE,repeat=TRUE;
 if(other==Fs)other=sys_winmgr_task;
 Sleep(100);
 Bool wm=Suspend(sys_winmgr_task),root=FALSE;
 if(adam_task!=Fs)root=Suspend(adam_task);
 before=Fs->data_heap->used_u8s;
 for(i=0;i<BLKDEVS_NUM;i++) {
   bd=BRBlockRecord(i);MemCpy(&saved[i],bd,sizeof(CBlkDev));MemSet(bd,0,sizeof(CBlkDev));
   selected=shape==1||shape==2&&!(i&1)||shape==3&&(i==0||i==BLKDEVS_NUM-1);
   bd->bd_signature=BD_SIGNATURE_VAL;bd->type=BDT_ATA;
   bd->flags=BDF_INITIALIZED|BDF_INIT_IN_PROGRESS|BDF_READ_ONLY|BDF_READ_CACHE;
   bd->locked_flags=65;bd->owning_task=other;bd->first_drv_let='A'+i;
   bd->max_blk=1000+i;bd->base0=200+i;
   if(selected)bd->owning_task=Fs;
   if(mode>=4) {
     if(i%3==1)bd->bd_signature=0;
     if(i%3==2)bd->locked_flags=64;
   }
   MemCpy(&expected[i],bd,sizeof(CBlkDev));
   if(selected&&bd->bd_signature==BD_SIGNATURE_VAL&&(bd->locked_flags&1)) {
     expected[i].locked_flags=64;expected[i].owning_task=NULL;
     expected[i].flags&=~(BDF_INITIALIZED|BDF_INIT_IN_PROGRESS);
   }
 }
 BlkDevsRelease;
 for(i=0;i<BLKDEVS_NUM;i++) {
   bd=BRBlockRecord(i);
   for(j=0;j<sizeof(CBlkDev);j++)if(bd(U8 *)[j]!=(&expected[i])(U8 *)[j])exact=FALSE;
 }
 if(exact)m|=1;
 if(Fs->cur_dv==current&&current->bd&&BRHasDevice)m|=2;
 BlkDevsRelease;
 for(i=0;i<BLKDEVS_NUM;i++) {
   bd=BRBlockRecord(i);
   for(j=0;j<sizeof(CBlkDev);j++)if(bd(U8 *)[j]!=(&expected[i])(U8 *)[j])repeat=FALSE;
   MemCpy(bd,&saved[i],sizeof(CBlkDev));
 }
 if(repeat)m|=4;
 if(Fs->data_heap->used_u8s==before)m|=8;
 if(Fs->cur_dv==current&&Fs->cur_dir==directory&&DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
 if(adam_task!=Fs)Suspend(adam_task,root);Suspend(sys_winmgr_task,wm);
 return m;
}
I64 BRTableCheck(I64 mode){I64 m=BRTable(mode);if(m!=31)throw('BlkTbl',TRUE);return m;}
