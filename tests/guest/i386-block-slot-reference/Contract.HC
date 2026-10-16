#ifndef BS_TABLE_ENTER
#define BS_TABLE_ENTER
#define BS_TABLE_LEAVE
#endif
I64 BSContract(I64 mode)
{
 CBlkDev saved[BLKDEVS_NUM],expected[BLKDEVS_NUM],*bd,*res=NULL,*again=NULL;
 CDrv *current=Fs->cur_dv;U8 *directory=Fs->cur_dir;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 I64 i,j,before,m=0,type=BDT_ATA,slot=0,kind=mode/3;
 U8 letter='C';Bool caught=FALSE,exact=TRUE,repeat=TRUE;
 if(mode<15) {
   type=kind+1;slot=0;if(mode%3==1)slot=13;if(mode%3==2)slot=BLKDEVS_NUM-1;
   if(kind==0)letter='A';if(kind==2)letter='M';if(kind==3)letter='Q';if(kind==4)letter='T';
 } else if(mode==15)slot=-1;
 else if(mode==16)letter='A';
 else if(mode==17){letter='?';type=BDT_NULL;}
 else if(mode==18)letter='c';
 else if(mode==19)type=-1;
 Sleep(100);
 Bool wm=Suspend(sys_winmgr_task),root=FALSE;
 if(adam_task!=Fs)root=Suspend(adam_task);
 BS_TABLE_ENTER
 before=Fs->data_heap->used_u8s;
 for(i=0;i<BLKDEVS_NUM;i++) {
   bd=BSRecord(i);MemCpy(&saved[i],bd,sizeof(CBlkDev));
   MemSet(bd,0xA5,sizeof(CBlkDev));bd->bd_signature=BD_SIGNATURE_VAL;
   if(i==slot)bd->bd_signature=0;
   MemCpy(&expected[i],bd,sizeof(CBlkDev));
 }
 if(mode!=15&&mode!=16&&mode!=19) {
   bd=&expected[slot];MemSet(bd,0,sizeof(CBlkDev));
   bd->first_drv_let=letter;bd->type=type;bd->flags=BDF_READ_CACHE;
   bd->blk_size=BLK_SIZE;bd->max_blk=0xEFFFFFFF;
   if(type==BDT_RAM)bd->flags=0;
   if(type==BDT_ISO_FILE_READ)bd->flags|=BDF_READ_ONLY;
   if(type==BDT_ATAPI){bd->flags|=BDF_REMOVABLE|BDF_READ_ONLY;bd->blk_size=DVD_BLK_SIZE;}
 }
 try {res=BlkDevNextFreeSlot(letter,type);}
 catch {caught=Fs->except_ch=='BlkDev';Fs->catch_except=TRUE;}
 if(mode==15||mode==16||mode==19) {if(caught&&!res)m|=1;}
 else if(!caught&&res==BSRecord(slot))m|=1;
 for(i=0;i<BLKDEVS_NUM;i++) {
   bd=BSRecord(i);
   for(j=0;j<sizeof(CBlkDev);j++)if(bd(U8 *)[j]!=(&expected[i])(U8 *)[j])exact=FALSE;
 }
 if(exact)m|=2;
 if(res) {
   try {again=BlkDevNextFreeSlot(letter,type);}
   catch {repeat=FALSE;Fs->catch_except=TRUE;}
   if(again!=res)repeat=FALSE;
 }
 for(i=0;i<BLKDEVS_NUM;i++) {
   bd=BSRecord(i);
   for(j=0;j<sizeof(CBlkDev);j++)if(bd(U8 *)[j]!=(&expected[i])(U8 *)[j])repeat=FALSE;
   MemCpy(bd,&saved[i],sizeof(CBlkDev));
 }
 if(repeat)m|=4;
 if(Fs->data_heap->used_u8s==before)m|=8;
 if(Fs->cur_dv==current&&Fs->cur_dir==directory&&DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
 BS_TABLE_LEAVE
 if(adam_task!=Fs)Suspend(adam_task,root);Suspend(sys_winmgr_task,wm);
 return m;
}
I64 BSCheck(I64 mode){I64 m=BSContract(mode);if(m!=31)throw('BlkSlot',TRUE);return m;}
