#ifndef I386_FILE_VOLUMES_CORE_INCLUDED
#define I386_FILE_VOLUMES_CORE_INCLUDED
#include "/Kernel/I386/FileContext.HH"
CDrv *I386TaskFilesDriveInit(CI386FileVolumes *volumes,U8 drive)
{
  CI386RedSea *volume;
  CDrv *identity;
  U8 *bytes;
  I64 i;
  if(!volumes || drive<'A' || drive>'Z' || !(volume=volumes->letter[drive-'A'])) return 0;
  identity=&volumes->drives[drive-'A'];
  if(!I386RedSeaValid(volume)) {identity->dv_signature=0;return 0;}
  if(!volume->disk->public_device || volume->disk->public_device->bd_signature!=BD_SIGNATURE_VAL) {
    identity->dv_signature=0;return 0;
  }
  if(identity->dv_signature!=DRV_SIGNATURE_VAL) {
    bytes=identity;for(i=0;i<sizeof(CDrv);i++)bytes[i]=0;
  }
  identity->drv_let=drive; identity->fs_type=1; //Canonical FSt_REDSEA.
  identity->drv_offset=volume->start; identity->size=volume->sectors;
  identity->root_clus=volume->root;
  identity->bd=volume->disk->public_device;
  if(!identity->bd->first_drv_let)identity->bd->first_drv_let=drive;
  identity->dv_signature=DRV_SIGNATURE_VAL;
  volume->public_drive=identity;
  volumes->initialized_drives|=1<<(drive-'A');
  return identity;
}
CDrv *I386TaskFilesDrive(CI386FileVolumes *volumes,U8 drive)
{//Mapping initialization is independent from physical record publication.
  I64 i;
  if(!volumes || drive<'A' || drive>'Z')return 0;
  if(!volumes->map_initialized) {
    volumes->block_globals.drvs=volumes->drives;
    for(i=0;i<26;i++)volumes->block_globals.let_to_drv[i]=&volumes->drives[i];
    volumes->map_initialized=TRUE;
  }
  for(i=0;i<26;i++)if(volumes->letter[i] && !(volumes->initialized_drives&(1<<i)))
    I386TaskFilesDriveInit(volumes,'A'+i);
  return volumes->block_globals.let_to_drv[drive-'A'];
}
Bool I386FileVolumeSame(CI386RedSea *a,CI386RedSea *b)
{
  return a && b && a->disk==b->disk && a->start==b->start &&
    a->sectors==b->sectors && a->root==b->root;
}
CI386RedSea *I386FileVolume(CI386FileVolumes *volumes,U8 drive,CI386RedSea *view)
{//Views borrow a mounted backend, but locks belong to the actual mapped record.
  CDrv *identity=I386TaskFilesDrive(volumes,drive);
  CI386RedSea *volume;
  I64 i,j;
  if(!identity || identity->dv_signature!=DRV_SIGNATURE_VAL || identity->fs_type!=1 ||
      !identity->bd || identity->bd->bd_signature!=BD_SIGNATURE_VAL)return 0;
  for(i=0;i<26;i++) {
    volume=volumes->letter[i];
    if(I386RedSeaValid(volume) && volume->disk->public_device==identity->bd &&
        volume->start==identity->drv_offset && volume->sectors==identity->size) {
      if(volume->public_drive==identity && volume->root==identity->root_clus)return volume;
      if(!view)return 0;
      for(j=0;j<sizeof(CI386RedSea);j++)view(U8 *)[j]=volume(U8 *)[j];
      view->backing=volume;view->public_drive=identity;view->root=identity->root_clus;
      view->public_drive_active=FALSE;view->public_drive_unlock=FALSE;
      if(I386RedSeaValid(view))return view;
      return 0;
    }
  }
  return 0;
}
Bool I386FileVolumeEnd(CI386FileVolumes *volumes,CI386RedSea *volume)
{//Propagate mutation uncertainty from an external-record view to its backend.
  Bool result=I386RedSeaEnd(volume);
  I64 i;CI386RedSea *backing;
  if(volume && !volume->signature)for(i=0;i<26;i++) {
    backing=volumes->letter[i];
    if(backing && backing->disk==volume->disk && backing->start==volume->start &&
        backing->sectors==volume->sectors)backing->signature=0;
  }
  return result;
}
#endif
