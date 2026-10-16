Bool RFState(CDrv *dv,CBlkDev *device,CBlkDev *controller,Bool forward,Bool held)
{
 CBlkDev *lock=device;CTask *owner=NULL;
 if(forward)lock=controller;if(held)owner=Fs;
 return dv->locked_flags==(64+held)&&dv->owning_task==owner&&
   lock->locked_flags==(128+held)&&lock->owning_task==owner&&
   (!forward||(device->locked_flags==128&&!device->owning_task));
}
I64 RFContract(I64 mode)
{
 CDrv dv;CBlkDev device,controller;CFreeLst *node,*last;
 I64 shape=mode%3,locks=mode/3%4,i,m=0,before,owner_before;
 Bool forward=mode>=12,held,suspended=Suspend(sys_winmgr_task),owner_suspended=FALSE;
 CTask *owner=Fs;
 if(mode>=24){shape=2;locks=(mode-24)%4;forward=mode>=28;owner=adam_task;}
 //Let the command key-up reach the input queue before measuring its owner heap.
 if(owner!=Fs){Sleep(100);owner_suspended=Suspend(owner);}
 held=locks>=2;before=Fs->data_heap->used_u8s;owner_before=owner->data_heap->used_u8s;
 MemSet(&dv,0,sizeof(CDrv));MemSet(&device,0,sizeof(CBlkDev));
 MemSet(&controller,0,sizeof(CBlkDev));
 dv.dv_signature=DRV_SIGNATURE_VAL;dv.bd=&device;dv.locked_flags=64;
 dv.size=12345;dv.root_clus=77;
 device.bd_signature=controller.bd_signature=BD_SIGNATURE_VAL;
 device.type=controller.type=BDT_ATA;
 device.locked_flags=controller.locked_flags=128;
 device.flags=controller.flags=BDF_INITIALIZED|BDF_READ_CACHE;
 if(forward)device.lock_fwding=&controller;
 if(shape){QueInit(&dv.next_free);if(shape==2)for(i=0;i<3;i++){
   node=CAlloc(sizeof(CFreeLst),owner);node->start=100+i;node->size=10+i;
   QueIns(node,dv.last_free);
 }}
 last=dv.last_free;
 if(locks==1)BlkDevLock(&device);
 if(locks>=2)DrvLock(&dv);
 if(locks==3)BlkDevUnlock(&device);
 RedSeaFreeFreeLst(&dv);
 if(!dv.next_free)m|=1;
 if(dv.last_free==last)m|=2;
 if(Fs->data_heap->used_u8s==before&&owner->data_heap->used_u8s==owner_before)m|=4;
 if(RFState(&dv,&device,&controller,forward,held))m|=8;
 if(dv.size==12345&&dv.root_clus==77&&dv.dv_signature==DRV_SIGNATURE_VAL&&dv.bd==&device&&
   device.flags==(BDF_INITIALIZED|BDF_READ_CACHE)&&controller.flags==device.flags&&
   (owner==Fs||IsSuspended(owner))&&
   ((forward&&device.lock_fwding==&controller)||(!forward&&!device.lock_fwding)))m|=16;
 RedSeaFreeFreeLst(&dv);
 if(!dv.next_free&&dv.last_free==last&&Fs->data_heap->used_u8s==before&&owner->data_heap->used_u8s==owner_before&&
   RFState(&dv,&device,&controller,forward,held))m|=32;
 DrvUnlock(&dv);BlkDevUnlock(&device);
 if(owner!=Fs)Suspend(owner,owner_suspended);Suspend(sys_winmgr_task,suspended);
 return m;
}
I64 RFCheck(I64 mode){I64 m=RFContract(mode);if(m!=63)throw('FreeList',TRUE);return m;}
