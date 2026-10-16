class DDGuard {I64 before;CDrv dv;I64 after;};
I64 DDMapped(I64 mode)
{
 CDrv saved,*drive=Fs->cur_dv,*current=Fs->cur_dv;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 U8 *directory=Fs->cur_dir,letter;
 I64 before,i,m=0;Bool zero=TRUE,ok=FALSE;
 Bool wm=Suspend(sys_winmgr_task),root=FALSE;
 if(adam_task!=Fs)root=Suspend(adam_task);
 if(mode>=4)drive=Let2Drv(':');
 letter=Drv2Let(drive);MemCpy(&saved,drive,sizeof(CDrv));
 before=Fs->data_heap->used_u8s;
 //Borrow the live record, keeping its real allocations alive for restoration.
 drive->next_free=NULL;drive->last_free=NULL;drive->cur_fat_blk=NULL;drive->fis=NULL;
 try {
   DrvDel(drive);
   for(i=0;i<sizeof(CDrv);i++)if(drive(U8 *)[i])zero=FALSE;
   if(zero)m|=1;
   if(mode%4==0)ok=Let2Drv(letter,FALSE)==NULL;
   if(mode%4==1)ok=Let2Drv(letter-'A'+'a',FALSE)==NULL;
   if(mode%4==2)ok=Let2BlkDev(letter,FALSE)==NULL;
   if(mode%4==3)ok=Let2BlkDev(letter-'A'+'a',FALSE)==NULL;
   if(ok)m|=2;
   zero=TRUE;for(i=0;i<sizeof(CDrv);i++)if(drive(U8 *)[i])zero=FALSE;
   if(zero)m|=4;
 } catch {Fs->catch_except=TRUE;}
 MemCpy(drive,&saved,sizeof(CDrv));
 zero=TRUE;for(i=0;i<sizeof(CDrv);i++)if(drive(U8 *)[i]!=(&saved)(U8 *)[i])zero=FALSE;
 if(zero&&Let2Drv(letter)==drive)m|=8;
 if(Fs->cur_dv==current&&Fs->cur_dir==directory&&DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
 if(Fs->data_heap->used_u8s==before)m|=32;
 if(adam_task!=Fs)Suspend(adam_task,root);Suspend(sys_winmgr_task,wm);
 return m;
}
I64 DDContract(I64 mode)
{
 if(mode>=48)return DDMapped(mode-48);
 DDGuard guard;CDrv *dv=&guard.dv;CBlkDev device,controller,*lock=&device;
 CFreeLst *nodes[3],*node;CTask *owner=Fs,*expected_owner=NULL;
 I64 shape=mode%3,locks=mode/3%4,buffers=mode%4,i,m=0,before,owner_before,remaining=0;
 Bool forward=mode>=12,held,zero=TRUE,suspended=Suspend(sys_winmgr_task),owner_suspended=FALSE;
 if(mode>=24){shape=2;buffers=3;locks=(mode-24)%4;forward=mode>=28;owner=adam_task;}
 if(mode>=32){owner=Fs;locks=(mode-32)%4;forward=(mode-32)%8>=4;}
 if(owner!=Fs){Sleep(100);owner_suspended=Suspend(owner);}
 before=Fs->data_heap->used_u8s;owner_before=owner->data_heap->used_u8s;
 MemSet(&guard,0,sizeof(DDGuard));MemSet(&device,0,sizeof(CBlkDev));MemSet(&controller,0,sizeof(CBlkDev));
 guard.before=0x123456789ABCDEF0;guard.after=0xFEDCBA9876543210;
 dv->dv_signature=DRV_SIGNATURE_VAL;dv->bd=&device;dv->locked_flags=64;
 dv->fs_type=FSt_REDSEA;if(mode>=32)dv->fs_type=FSt_FAT32;if(mode>=40)dv->fs_type=FSt_NULL;
 dv->size=12345;dv->root_clus=77;
 device.bd_signature=controller.bd_signature=BD_SIGNATURE_VAL;
 device.type=controller.type=BDT_ATA;device.locked_flags=controller.locked_flags=128;
 device.flags=controller.flags=BDF_INITIALIZED|BDF_READ_CACHE;
 if(forward){device.lock_fwding=&controller;lock=&controller;}
 if(shape){QueInit(&dv->next_free);if(shape==2)for(i=0;i<3;i++){
   nodes[i]=node=CAlloc(sizeof(CFreeLst),owner);node->start=100+i;node->size=10+i;
   QueIns(node,dv->last_free);
 }}
 if(mode>=32)remaining=owner->data_heap->used_u8s-owner_before;
 if(buffers&1)dv->cur_fat_blk=CAlloc(512,owner);
 if(buffers&2)dv->fis=CAlloc(512,owner);
 if(locks==1)BlkDevLock(&device);
 if(locks>=2)DrvLock(dv);
 if(locks==3)BlkDevUnlock(&device);
 held=locks==1||locks==2;if(mode<32&&shape)held=locks>=2;
 if(held)expected_owner=Fs;
 DrvDel(dv);
 for(i=0;i<sizeof(CDrv);i++)if(dv(U8 *)[i])zero=FALSE;
 if(zero)m|=1;
 if(guard.before==0x123456789ABCDEF0&&guard.after==0xFEDCBA9876543210)m|=2;
 if(owner->data_heap->used_u8s==owner_before+remaining&&
   (owner==Fs||Fs->data_heap->used_u8s==before))m|=4;
 if(lock->locked_flags==128+held&&lock->owning_task==expected_owner&&
   (!forward||(device.locked_flags==128&&!device.owning_task))&&
   device.flags==(BDF_INITIALIZED|BDF_READ_CACHE)&&controller.flags==device.flags)m|=8;
 zero=TRUE;DrvDel(dv);
 for(i=0;i<sizeof(CDrv);i++)if(dv(U8 *)[i])zero=FALSE;
 if(zero&&owner->data_heap->used_u8s==owner_before+remaining&&
   lock->locked_flags==128+held&&lock->owning_task==expected_owner)m|=16;
 zero=TRUE;
 if(mode>=32)for(i=0;i<3;i++){
   if(nodes[i]->start!=100+i||nodes[i]->size!=10+i||MHeapCtrl(nodes[i])!=owner->data_heap)zero=FALSE;
   Free(nodes[i]);
 }
 if(zero&&Fs->data_heap->used_u8s==before&&owner->data_heap->used_u8s==owner_before)m|=32;
 BlkDevUnlock(&device);
 if(owner!=Fs)Suspend(owner,owner_suspended);Suspend(sys_winmgr_task,suspended);
 return m;
}
I64 DDCheck(I64 mode){I64 m=DDContract(mode);if(m!=63)throw('DriveDel',TRUE);return m;}
