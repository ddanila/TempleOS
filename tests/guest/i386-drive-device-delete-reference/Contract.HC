I64 DBContract(I64 mode)
{
 CDrv saved[DRVS_NUM],expected[DRVS_NUM],*dv;
 CBlkDev device,other,*target=&device;
 CFreeLst *node;
 CDrv *current=Fs->cur_dv;U8 *directory=Fs->cur_dir;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 I64 i,j,before,m=0,shape=mode%4;
 Bool match,zero=TRUE,kept=TRUE,repeat=TRUE;
 Sleep(100);
 Bool wm=Suspend(sys_winmgr_task),root=FALSE;
 if(adam_task!=Fs)root=Suspend(adam_task);
 before=Fs->data_heap->used_u8s;
 MemSet(&device,0,sizeof(CBlkDev));MemSet(&other,0,sizeof(CBlkDev));
 device.bd_signature=other.bd_signature=BD_SIGNATURE_VAL;
 device.type=other.type=BDT_ATA;device.flags=other.flags=BDF_INITIALIZED;
 device.locked_flags=other.locked_flags=128;
 if(mode>=4)target=NULL;
 for(i=0;i<DRVS_NUM;i++) {
   //The canonical table must remain accessible without caller directory state.
   Fs->cur_dv=NULL;Fs->cur_dir=NULL;dv=DBRecord(i);
   Fs->cur_dv=current;Fs->cur_dir=directory;
   MemCpy(&saved[i],dv,sizeof(CDrv));MemSet(dv,0,sizeof(CDrv));
   match=shape==1||shape==2&&!(i&1)||shape==3&&(i==0||i==DRVS_NUM-1);
   dv->bd=&other;if(match)dv->bd=target;
   dv->dv_signature=DRV_SIGNATURE_VAL;dv->drv_let='A'+i;dv->fs_type=FSt_REDSEA;
   dv->size=1000+i;dv->root_clus=50+i;dv->locked_flags=64;
   if(match) {
     if(i&1)dv->cur_fat_blk=CAlloc(512);
     if(i&2)dv->fis=CAlloc(512);
     if(target) {
       QueInit(&dv->next_free);node=CAlloc(sizeof(CFreeLst));
       node->start=i;node->size=i+1;QueIns(node,dv->last_free);
     }
   }
   MemCpy(&expected[i],dv,sizeof(CDrv));
 }
 DrvBlkDevDel(target);
 for(i=0;i<DRVS_NUM;i++) {
   dv=DBRecord(i);
   if(expected[i].bd==target) {
     for(j=0;j<sizeof(CDrv);j++)if(dv(U8 *)[j])zero=FALSE;
   } else for(j=0;j<sizeof(CDrv);j++)if(dv(U8 *)[j]!=(&expected[i])(U8 *)[j])kept=FALSE;
   MemCpy(&expected[i],dv,sizeof(CDrv));
 }
 if(zero)m|=1;if(kept)m|=2;
 if(Fs->data_heap->used_u8s==before)m|=4;
 if(device.locked_flags==128&&!device.owning_task&&device.flags==BDF_INITIALIZED&&
   other.locked_flags==128&&!other.owning_task&&other.flags==BDF_INITIALIZED)m|=8;
 DrvBlkDevDel(target);
 for(i=0;i<DRVS_NUM;i++) {
   dv=DBRecord(i);
   for(j=0;j<sizeof(CDrv);j++)if(dv(U8 *)[j]!=(&expected[i])(U8 *)[j])repeat=FALSE;
   MemCpy(dv,&saved[i],sizeof(CDrv));
 }
 if(repeat&&Fs->data_heap->used_u8s==before)m|=16;
 if(Fs->cur_dv==current&&Fs->cur_dir==directory&&DocPut==put&&DocDisplay==display&&DocBorder==border)m|=32;
 if(adam_task!=Fs)Suspend(adam_task,root);Suspend(sys_winmgr_task,wm);
 return m;
}
I64 DBCheck(I64 mode){I64 m=DBContract(mode);if(m!=63)throw('DrvBdDel',TRUE);return m;}
