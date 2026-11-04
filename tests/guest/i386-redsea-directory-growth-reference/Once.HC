extern U0 RedSeaFmt(U8 drv_let,Bool quick=TRUE);
extern U0 RedSeaFreeFreeLst(CDrv *dv);
U0 GrowthReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 DirectoryGrowthContract()
{
  CDrv dv;CBlkDev bd;CDrv *saved=blkdev.let_to_drv[25],*old_dv=Fs->cur_dv;
  U8 *old_dir=StrNew(Fs->cur_dir),*name;U8 data[512],message[128];
  CFile *f;CDirEntry child,grand;CDirEntry *parent;I64 i,old_root,old_child,root_parent,child_parent,mask=0;
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));MemSet(data,0x5A,512);
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.fs_type=FSt_REDSEA;
  dv.bd=&bd;dv.size=128;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED;
  bd.first_drv_let='Z';bd.max_blk=127;bd.blk_size=512;bd.init_root_dir_blks=1;
  bd.RAM_dsk=CAlloc(128*512);blkdev.let_to_drv[25]=&dv;
  RedSeaFmt('Z');Drv('Z');
  if(!DirMk("Child"))throw('Grow1',TRUE);
  if(!DirMk("Child/Grand"))throw('Grow4',TRUE);
  old_root=dv.root_clus;
  for(i=0;i<7;i++) {
    name=MStrPrint("New%d",i);if(!DirMk(name))throw('Grow5',TRUE);Free(name);
  }
  for(i=0;i<16;i++) {
    name=MStrPrint("File%02d.DATA",i);f=FOpen(name,"w",1);Free(name);
    if(!f||!FBlkWrite(f,data,0,1))throw('Grow2',TRUE);FClose(f);
  }
  if(!FileFind("Child",&child,FUF_JUST_DIRS))throw('Grow3',TRUE);
  parent=bd.RAM_dsk+dv.root_clus*512+64-offset(CDirEntry.start);root_parent=parent->clus;
  parent=bd.RAM_dsk+child.clus*512+64-offset(CDirEntry.start);child_parent=parent->clus;
  if(dv.root_clus!=old_root)mask|=1;
  if(root_parent==dv.root_clus)mask|=2;
  if(child_parent==dv.root_clus)mask|=4;
  StrPrint(message,"GROW ROOT %d %d PARENTS %d %d MASK %d\n",old_root,dv.root_clus,root_parent,child_parent,mask);GrowthReport(message);
  old_child=child.clus;Free(child.full_name);
  if(!Cd("Child"))throw('Grow6',TRUE);
  for(i=0;i<16;i++) {
    name=MStrPrint("File%02d.DATA",i);f=FOpen(name,"w",1);Free(name);
    if(!f||!FBlkWrite(f,data,0,1))throw('Grow7',TRUE);FClose(f);
  }
  if(!FileFind("Z:/Child",&child,FUF_JUST_DIRS)||!FileFind("Z:/Child/Grand",&grand,FUF_JUST_DIRS))throw('Grow8',TRUE);
  if(child.clus!=old_child)mask|=8;
  parent=bd.RAM_dsk+grand.clus*512+64-offset(CDirEntry.start);
  if(parent->clus==child.clus)mask|=16;
  parent=bd.RAM_dsk+child.clus*512+64-offset(CDirEntry.start);
  if(parent->clus==dv.root_clus)mask|=32;
  StrPrint(message,"GROW CHILD %d %d MASK %d\n",old_child,child.clus,mask);GrowthReport(message);
  Free(child.full_name);Free(grand.full_name);Drv(Drv2Let(old_dv));Cd(old_dir);Free(old_dir);
  RedSeaFreeFreeLst(&dv);Free(dv.cur_fat_blk);Free(bd.RAM_dsk);blkdev.let_to_drv[25]=saved;
  return mask;
}
if(DirectoryGrowthContract!=63)GrowthReport("FAIL RedSea directory growth\n");
else GrowthReport("PASS RedSea directory growth\n");
GrowthReport("DONE RedSea directory growth\n");
