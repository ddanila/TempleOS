I64 BRContract(I64 mode)
{
 CDrv saved[DRVS_NUM],drive_expected,*dv;
 CBlkDev *bd=Fs->cur_dv->bd,original,expected,after;
 CTask *other=adam_task;
 CDrv *current=Fs->cur_dv;U8 *directory=Fs->cur_dir;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 I64 i,j,before,m=0,state=mode%4;
 Bool unchanged=TRUE,repeat=TRUE;
 while(bd->lock_fwding)bd=bd->lock_fwding;
 if(other==Fs)other=sys_winmgr_task;
 Sleep(100);
 Bool wm=Suspend(sys_winmgr_task),root=FALSE;
 if(adam_task!=Fs)root=Suspend(adam_task);
 before=Fs->data_heap->used_u8s;
 MemCpy(&original,bd,sizeof(CBlkDev));
 for(i=0;i<DRVS_NUM;i++) {
   dv=BRRecord(i);MemCpy(&saved[i],dv,sizeof(CDrv));
   if(mode>=4)dv->bd=NULL;
 }
 bd->locked_flags=65;bd->owning_task=Fs;
 bd->flags=BDF_INITIALIZED|BDF_INIT_IN_PROGRESS|BDF_READ_ONLY|BDF_READ_CACHE;
 if(state==1)bd->owning_task=NULL;
 if(state==2)bd->bd_signature=0;
 if(state==3)bd->owning_task=other;
 MemCpy(&expected,bd,sizeof(CBlkDev));
 if(!state) {
   expected.locked_flags=64;expected.owning_task=NULL;
   expected.flags&=~(BDF_INITIALIZED|BDF_INIT_IN_PROGRESS);
 }
 BlkDevsRelease;
 for(i=0;i<sizeof(CBlkDev);i++)if(bd(U8 *)[i]!=(&expected)(U8 *)[i])break;
 if(i==sizeof(CBlkDev))m|=1;
 for(i=0;i<DRVS_NUM;i++) {
   dv=BRRecord(i);
   MemCpy(&drive_expected,&saved[i],sizeof(CDrv));
   if(mode>=4)drive_expected.bd=NULL;
   for(j=0;j<sizeof(CDrv);j++)if(dv(U8 *)[j]!=(&drive_expected)(U8 *)[j])unchanged=FALSE;
 }
 if(unchanged)m|=2;
 MemCpy(&after,bd,sizeof(CBlkDev));BlkDevsRelease;
 for(i=0;i<sizeof(CBlkDev);i++)if(bd(U8 *)[i]!=(&after)(U8 *)[i])repeat=FALSE;
 if(repeat)m|=4;
 if(Fs->data_heap->used_u8s==before)m|=8;
 if(Fs->cur_dv==current&&Fs->cur_dir==directory&&DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
 MemCpy(bd,&original,sizeof(CBlkDev));
 //Restore caller-visible drive associations before returning to console or disk I/O.
 for(i=0;i<DRVS_NUM;i++)MemCpy(BRRecord(i),&saved[i],sizeof(CDrv));
 if(adam_task!=Fs)Suspend(adam_task,root);Suspend(sys_winmgr_task,wm);
 return m;
}
I64 BRCheck(I64 mode){I64 m=BRContract(mode);if(m!=31)throw('BlkRel',TRUE);return m;}
