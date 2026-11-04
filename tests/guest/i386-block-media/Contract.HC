U0 BlockMediaContract()
{
  CDrv dv;CDrv *saved=blkdev.let_to_drv[25];CBlkDev bd;
  CFile *f;CRedSeaBoot br;U8 *data=CAlloc(1536),*in=CAlloc(1538),*file,*ram,*name;
  U32 *fat1,*fat2;CDirEntry *dot;CDirEntry sub,grand;I64 i,j,a,size,old_size;Bool caught;
  //Interleave the original allocator with retained whole-file allocation.
  for(j=0;j<4;j++) {
    for(i=0;i<1536;i++)data[i]=i*13+j;
    if(!FileWrite("C:/media-provider.DATA",data,512))throw('MediaP1',TRUE);
    f=FOpen("C:/media-stream.DATA","w",2);
    if(!f||!FBlkWrite(f,data,0,2))throw('MediaP2',TRUE);
    if(!FileWrite("C:/media-provider.DATA",data+512,1024))throw('MediaP3',TRUE);
    FClose(f);
    file=FileRead("C:/media-stream.DATA",&size);
    if(!file||size!=1024||MemCmp(file,data,1024))throw('MediaP4',TRUE);
    Free(file);file=FileRead("C:/media-provider.DATA",&size);
    if(!file||size!=1024||MemCmp(file,data+512,1024))throw('MediaP5',TRUE);
    Free(file);
    if(Del("C:/media-stream.DATA",,,FALSE)!=1||Del("C:/media-provider.DATA",,,FALSE)!=1)throw('MediaP6',TRUE);
  }
  //Force root growth while both implementations create directory entries.
  if(!BlkRead(Fs->cur_dv,in,Fs->cur_dv->root_clus,1))throw('MediaG1',TRUE);
  dot=in-offset(CDirEntry.start);old_size=dot->size;
  for(j=0;j<20;j++) {
    for(i=0;i<512;i++)data[i]=i^j;
    name=MStrPrint("C:/MediaSG%02d.DATA",j);f=FOpen(name,"w",1);Free(name);
    if(!f||!FBlkWrite(f,data,0,1))throw('MediaG2',TRUE);
    FClose(f);
  }
  if(!BlkRead(Fs->cur_dv,in,Fs->cur_dv->root_clus,1)||dot->size<=old_size)throw('MediaG8',TRUE);
  dot=in+64-offset(CDirEntry.start);
  if(dot->clus!=Fs->cur_dv->root_clus)throw('MediaG9',TRUE);
  dot=in-offset(CDirEntry.start);
  for(j=0;j<20;j++) {
    for(i=0;i<512;i++)data[i]=i^j;
    name=MStrPrint("C:/MediaPG%02d.DATA",j);
    if(!FileWrite(name,data,512))throw('MediaG3',TRUE);Free(name);
  }
  if(!BlkRead(Fs->cur_dv,in,Fs->cur_dv->root_clus,1)||dot->size<=old_size)throw('MediaG4',TRUE);
  for(j=0;j<20;j++) {
    for(i=0;i<512;i++)data[i]=i^j;
    name=MStrPrint("C:/MediaSG%02d.DATA",j);file=FileRead(name,&size);Free(name);
    if(!file||size!=512||MemCmp(file,data,512))throw('MediaG5',TRUE);Free(file);
    name=MStrPrint("C:/MediaPG%02d.DATA",j);file=FileRead(name,&size);Free(name);
    if(!file||size!=512||MemCmp(file,data,512))throw('MediaG6',TRUE);Free(file);
  }
  if(Del("C:/MediaSG*.DATA",,,FALSE)!=20||Del("C:/MediaPG*.DATA",,,FALSE)!=20)throw('MediaG7',TRUE);
  //Relocating a non-root directory must also reparent its own children.
  if(!DirMk("C:/media-sub")||!DirMk("C:/media-sub/grand"))throw('MediaN1',TRUE);
  for(j=0;j<20;j++) {
    name=MStrPrint("C:/media-sub/MediaSG%02d.DATA",j);f=FOpen(name,"w",1);Free(name);
    if(!f||!FBlkWrite(f,data,0,1))throw('MediaN2',TRUE);FClose(f);
  }
  if(!FileFind("C:/media-sub",&sub,FUF_JUST_DIRS)||!FileFind("C:/media-sub/grand",&grand,FUF_JUST_DIRS))throw('MediaN4',TRUE);
  if(!BlkRead(Fs->cur_dv,in,grand.clus,1))throw('MediaN5',TRUE);
  dot=in+64-offset(CDirEntry.start);
  if(dot->clus!=sub.clus)throw('MediaN6',TRUE);
  Free(sub.full_name);Free(grand.full_name);
  if(Del("C:/media-sub/MediaSG*.DATA",,,FALSE)!=20||!DirDel("C:/media-sub/grand")||!DirDel("C:/media-sub"))throw('MediaN3',TRUE);
  //Exercise complete RAM initialization/formatting and block dispatch.
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.bd=&bd;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.first_drv_let='Z';
  bd.max_blk=511;bd.blk_size=512;bd.init_root_dir_blks=2;bd.RAM_dsk=CAlloc(512*512);
  blkdev.let_to_drv[25]=&dv;
  if(!BlkDevInit(&bd)||dv.fs_type!=FSt_REDSEA||dv.size!=512||!dv.cur_fat_blk)throw('MediaR1',TRUE);
  if(!BlkRead(&dv,&br,0,1)||br.signature!=0x88||br.signature2!=0xAA55||!br.root_clus)throw('MediaR2',TRUE);
  if(!BlkWrite(&dv,data,100,3))throw('MediaR3',TRUE);
  in[0]=0x5A;in[1537]=0xA5;
  if(!BlkRead(&dv,in+1,100,3)||MemCmp(in+1,data,1536)||in[0]!=0x5A||in[1537]!=0xA5)throw('MediaR4',TRUE);
  if(!BlkRead(&dv,NULL,0,0)||!BlkWrite(&dv,NULL,0,0))throw('MediaR5',TRUE);
  caught=FALSE;try BlkRead(&dv,in,512,1);catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught)throw('MediaR6',TRUE);
  bd.flags|=BDF_READ_ONLY;caught=FALSE;
  try BlkWrite(&dv,data,100,1);catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught)throw('MediaR7',TRUE);
  bd.flags|=BDF_READ_ONLY_OVERRIDE;
  if(!BlkWrite(&dv,data,100,1)||!DrvLock(&dv))throw('MediaR8',TRUE);
  if(!BlkRead(&dv,in,100,1)||DrvLock(&dv))throw('MediaR9',TRUE);
  DrvUnlock(&dv);bd.flags=BDF_INITIALIZED;
  CallExtStr("RedSeaFreeFreeLst",&dv);
  ram=bd.RAM_dsk;
  if(!FileWrite("C:/media-image.ISO.C",ram,512*512))throw('MediaI1',TRUE);
  Free(dv.cur_fat_blk);
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.bd=&bd;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_ISO_FILE_READ;bd.first_drv_let='Z';
  bd.blk_size=512;bd.file_dsk_name="C:/media-image.ISO.C";
  if(!BlkDevInit(&bd)||dv.size!=512||!BlkRead(&dv,&br,0,1)||br.signature!=0x88)throw('MediaI2',TRUE);
  FClose(bd.file_dsk);Free(dv.cur_fat_blk);
  if(Del("C:/media-image.ISO.C",,,FALSE)!=1)throw('MediaI3',TRUE);
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.bd=&bd;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_ISO_FILE_WRITE;bd.first_drv_let='Z';
  bd.blk_size=512;bd.max_blk=127;bd.init_root_dir_blks=2;
  if(!BlkDevInit(&bd)||StrCmp(bd.file_dsk_name,"C:/DrvZ.ISO.C")||dv.size!=128)throw('MediaI4',TRUE);
  if(!BlkRead(&dv,&br,0,1)||br.signature!=0x88||br.signature2!=0xAA55)throw('MediaI5',TRUE);
  FClose(bd.file_dsk);Free(bd.file_dsk_name);Free(dv.cur_fat_blk);
  if(Del("C:/DrvZ.ISO.C",,,FALSE)!=1)throw('MediaI6',TRUE);
  bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED;bd.RAM_dsk=ram;bd.max_blk=511;
  dv.size=512;dv.cur_fat_blk=CAlloc(512);
  //A private FAT32 volume exercises the actual fragmented stream branch.
  MemSet(bd.RAM_dsk,0,512*512);MemSet(dv.cur_fat_blk,0,512);
  dv.fs_type=FSt_FAT32;dv.spc=2;dv.data_area=10;dv.fat1=2;dv.fat2=6;
  dv.root_clus=2;dv.cur_fat_blk_num=0;dv.fat_blk_dirty=0;
  dv.file_system_info_sect=1;dv.fis=CAlloc(512);dv.fis->most_recently_alloced=2;
  fat1=bd.RAM_dsk+2*512;fat2=bd.RAM_dsk+6*512;
  fat1[0]=0x0FFFFFF8;fat1[1]=fat1[2]=0x0FFFFFFF;
  MemCpy(fat2,fat1,4*512);MemCpy(dv.cur_fat_blk,fat1,512);
  a=ClusAlloc(&dv,0,1,FALSE);
  if(ClusAlloc(&dv,0,1,FALSE)!=4||ClusAlloc(&dv,a,2,FALSE)!=5)throw('MediaF0',TRUE);
  if(a!=3||ClusNumNext(&dv,a,2)!=6||MemCmp(fat1,fat2,4*512))throw('MediaF1',TRUE);
  f=CAlloc(sizeof(CFile));f->dv=&dv;f->de.clus=a;f->max_blk=5;
  f->flags=FF_WRITE;f->clus=f->file_clus_num=INVALID_CLUS;f->clus_buf=CAlloc(1024);
  if(!FBlkWrite(f,data,0,3)||f->fblk_num!=3)throw('MediaF2',TRUE);
  if(!FBlkRead(f,in,0,3)||MemCmp(in,data,1536))throw('MediaF3',TRUE);
  FClose(f);
  for(i=0;i<1024;i++)if(bd.RAM_dsk[(dv.data_area+4*2)*512+i])throw('MediaF5',TRUE);
  if(ClusBlkRead(&dv,in,a,3)!=6||MemCmp(in,data,1536))throw('MediaF4',TRUE);
  Free(dv.cur_fat_blk);Free(dv.fis);Free(bd.RAM_dsk);
  blkdev.let_to_drv[25]=saved;Free(data);Free(in);
}
